terraform {
  required_providers {
    bytebase = {
      version = "0.0.9"
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
  resource_id = local.instance_id_test
  environment = bytebase_environment.test.resource_id
  title       = "Test Sample Instance"
  engine      = "POSTGRES"

  # You need to specific the data source
  data_sources {
    title    = "admin data source"
    type     = "ADMIN"
    username = "bbsample"
    password = ""
    host     = "/tmp"
    port     = "446"
  }
}

# Create a new instance named "prod instance"
resource "bytebase_instance" "prod" {
  resource_id = local.instance_id_prod
  environment = bytebase_environment.prod.resource_id
  title       = "Prod Sample Instance"
  engine      = "POSTGRES"

  # You need to specific the data source
  data_sources {
    title    = "admin data source"
    type     = "ADMIN"
    username = "bbsample"
    password = ""
    host     = "/tmp"
    port     = "447"
  }

  # Add another data_sources with RO type
  data_sources {
    title    = "read-only data source"
    type     = "READ_ONLY"
    username = local.readonly_role_name
    password = local.readonly_role_pwd
    host     = "/tmp"
    port     = "447"
  }
}

# Create a new role named "role_test_terraform" in the instance "test-sample-instance"
resource "bytebase_instance_role" "test" {
  name     = local.readonly_role_name
  instance = bytebase_instance.test.resource_id

  password         = local.readonly_role_pwd
  connection_limit = 10
  valid_until      = "2050-12-31T00:00:00+08:00"

  attribute {
    super_user  = false
    no_inherit  = false
    create_role = false
    create_db   = false
    can_login   = true
    replication = false
    bypass_rls  = false
  }
}

# Create a new project
resource "bytebase_project" "sample_project" {
  resource_id   = local.project_id
  title         = "Sample project"
  key           = "SAM"
  workflow      = "UI"
  schema_change = "DDL"
}
