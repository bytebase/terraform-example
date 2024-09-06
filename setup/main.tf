terraform {
  required_providers {
    bytebase = {
      version = "1.0.0"
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

# Create a new project
resource "bytebase_project" "sample_project" {
  resource_id = local.project_id
  title       = "Sample project"
  key         = "SAM"
}
