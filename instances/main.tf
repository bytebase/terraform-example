# Examples for query the instances
terraform {
  required_providers {
    bytebase = {
      version = "0.0.8"
      # For local development, please use "terraform.local/bytebase/bytebase" instead
      source = "registry.terraform.io/bytebase/bytebase"
    }
  }
}

provider "bytebase" {
  # You need to replace the account and key with your Bytebase service account.
  service_account = "terraform@service.bytebase.com"
  service_key     = "bbs_0T4ksbMCI9bKcOKWnom7"
  # The Bytebase service URL. You can use the external URL in production.
  # Check the docs about external URL: https://www.bytebase.com/docs/get-started/install/external-url
  url = "https://tf.bytebase.com"
}

locals {
  instance_id_test = "test-sample-instance"
  instance_id_prod = "prod-sample-instance"
}

# List all instances in all environments
data "bytebase_instance_list" "all" {}

output "all_instances" {
  value = data.bytebase_instance_list.all
}

# Find a specific instance by name
data "bytebase_instance" "test" {
  resource_id = local.instance_id_test
}

output "test_instance" {
  value = data.bytebase_instance.test
}

data "bytebase_instance" "prod" {
  resource_id = local.instance_id_prod
}

output "prod_instance" {
  value = data.bytebase_instance.prod
}