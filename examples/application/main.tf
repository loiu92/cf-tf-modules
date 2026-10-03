terraform {
  required_version = ">= 1.7"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

# The Cloudflare provider reads CLOUDFLARE_API_TOKEN from the environment.
# Provider configuration belongs to the consuming root, not shared modules.
provider "cloudflare" {}

module "application" {
  source      = "../../modules/application"
  account_id  = var.account_id
  project     = var.project
  environment = var.environment
  recipe      = var.recipe
}

output "worker_name" { value = module.application.worker_name }
output "bindings" { value = module.application.bindings }
