terraform {
  required_providers {
    bytebase = {
      version = "1.0.7"
      # For local development, please use "terraform.local/bytebase/bytebase" instead
      source = "registry.terraform.io/bytebase/bytebase"
    }
  }
}

provider "bytebase" {
  # You need to replace the account and key with your Bytebase service account.
  service_account = "terraform@service.bytebase.com"
  service_key     = "bbs_ahZfZeZhLZLnfvDeaVb1"
  # The Bytebase service URL. You can use the external URL in production.
  # Check the docs about external URL: https://www.bytebase.com/docs/get-started/install/external-url
  url = "https://tf.bytebase.com"
}

# Correspond to the sample data Bytebase generates during onboarding.
locals {
  environment_id_test = "test"
  environment_id_prod = "prod"
  instance_id_test    = "test-sample-instance"
  instance_id_prod    = "prod-sample-instance"
  readonly_role_name  = "bbsample_readonly"
  readonly_role_pwd   = "12345"
  project_id          = "project-sample"
}

# Configure the workspace profile setting.
resource "bytebase_setting" "workspace_profile" {
  name = "bb.workspace.profile"

  workspace_profile {
    external_url = "https://bytebase.example.com"
    domains      = ["bytebase.com"]
  }
}


# Create a new environment named "Test"
resource "bytebase_environment" "test" {
  resource_id             = local.environment_id_test
  title                   = "Test"
  order                   = 0
  environment_tier_policy = "UNPROTECTED"
}

# Create another environment named "Prod"
resource "bytebase_environment" "prod" {
  resource_id             = local.environment_id_prod
  title                   = "Prod"
  order                   = 1
  environment_tier_policy = "PROTECTED"
}

# Create a new instance named "test instance"
# You can replace the parameters with your real instance
resource "bytebase_instance" "test" {
  depends_on = [
    bytebase_environment.test
  ]

  resource_id = local.instance_id_test
  environment = bytebase_environment.test.name
  title       = "Test Sample Instance"
  engine      = "POSTGRES"

  # You need to specific the data source
  data_sources {
    id       = "64065943-6ce5-4d50-b145-5c0ddb952a74"
    type     = "ADMIN"
    username = "bbsample"
    password = ""
    host     = "/tmp"
    port     = "446"
  }
}

# Create a new instance named "prod instance"
resource "bytebase_instance" "prod" {
  depends_on = [
    bytebase_environment.prod
  ]

  resource_id = local.instance_id_prod
  environment = bytebase_environment.prod.name
  title       = "Prod Sample Instance"
  engine      = "POSTGRES"

  # You need to specific the data source
  data_sources {
    id       = "055c4790-e624-4248-8500-1803febb373c"
    type     = "ADMIN"
    username = "bbsample"
    password = ""
    host     = "/tmp"
    port     = "447"
  }

  # Add another data_sources with RO type
  data_sources {
    id       = "479b2901-f8f5-49d6-85d7-f5962f2e58da"
    type     = "READ_ONLY"
    username = local.readonly_role_name
    password = local.readonly_role_pwd
    host     = "/tmp"
    port     = "447"
  }
}

# Create or update the user.
resource "bytebase_user" "workspace_dba" {
  title = "DBA"
  email = "dba@bytebase.com"

  # Grant workspace level roles.
  roles = ["roles/workspaceDBA"]
}

# Create or update the user.
resource "bytebase_user" "project_developer" {
  title = "Developer"
  email = "developer@bytebase.com"

  # Grant workspace level roles, will grant projectViewer for this user in all projects.
  roles = ["roles/projectViewer"]
}

# Create or update the group.
resource "bytebase_group" "developers" {
  depends_on = [
    bytebase_user.workspace_dba,
    bytebase_user.project_developer,
    # group requires the domain.
    bytebase_setting.workspace_profile
  ]

  email = "developers@bytebase.com"
  title = "Bytebase Developers"

  members {
    member = format("users/%s", bytebase_user.workspace_dba.email)
    role   = "OWNER"
  }

  members {
    member = format("users/%s", bytebase_user.project_developer.email)
    role   = "MEMBER"
  }
}

# Create a new project.
resource "bytebase_project" "sample_project" {
  depends_on = [
    bytebase_user.workspace_dba,
    bytebase_user.project_developer,
    bytebase_group.developers,
  ]

  resource_id = local.project_id
  title       = "Sample project"
  key         = "SAM"

  members {
    member = format("user:%s", bytebase_user.workspace_dba.email)
    role   = "roles/projectOwner"
  }

  members {
    member = format("group:%s", bytebase_group.developers.email)
    role   = "roles/projectDeveloper"
  }
}

# Custom the approval flow. Require ENTERPRISE subscription.
resource "bytebase_setting" "approval_flow" {
  name = "bb.workspace.approval"
  approval_flow {
    rules {
      flow {
        title       = "DBA -> OWNER"
        description = "Need DBA and workspace owner approval"
        creator     = "users/support@bytebase.com"

        # Approval flow following the step order.
        steps {
          type = "GROUP"
          node = "WORKSPACE_DBA"
        }

        steps {
          type = "GROUP"
          node = "WORKSPACE_OWNER"
        }
      }

      # Match any condition will trigger this approval flow.
      conditions {
        source = "DML"
        level  = "MODERATE"
      }
      conditions {
        source = "DDL"
        level  = "HIGH"
      }
    }
  }
}



# Data masking
resource "bytebase_setting" "classification" {
  name = "bb.workspace.data-classification"

  classification {
    id    = "unique-id"
    title = "Classification Example"

    levels {
      id    = "1"
      title = "Level 1"
    }
    levels {
      id    = "2"
      title = "Level 2"
    }

    classifications {
      id    = "1"
      title = "Basic"
    }
    classifications {
      id    = "1-1"
      title = "User basic info"
      level = "2"
    }
    classifications {
      id    = "1-2"
      title = "User contact info"
      level = "2"
    }
    classifications {
      id    = "2"
      title = "Relationship"
    }
    classifications {
      id    = "2-1"
      title = "Social info"
      level = "2"
    }
  }
}

resource "bytebase_database_catalog" "employee_catalog" {
  depends_on = [
    bytebase_instance.test,
    bytebase_setting.classification
  ]

  database = format("%s/databases/employee", bytebase_instance.test.name)

  schemas {
    tables {
      name = "salary"
      columns {
        name           = "amount"
        semantic_type  = "default"
        classification = "1-1-1"
      }
      columns {
        name          = "emp_no"
        semantic_type = "default-partial"
        labels = {
          tenant = "example"
          region = "asia"
        }
      }
    }
  }
}
