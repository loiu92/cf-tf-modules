terraform {
  required_version = ">= 1.7"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      # oauth_configuration on zero_trust_access_application landed in 5.19.
      version = ">= 5.19.0, < 6.0.0"
    }
  }
}
