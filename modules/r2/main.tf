# R2 bucket with optional lifecycle configuration.

resource "cloudflare_r2_bucket" "bucket" {
  account_id = var.account_id
  name       = var.name
  location   = var.location_hint
}

resource "cloudflare_r2_bucket_lifecycle" "lifecycle" {
  count = var.lifecycle_rules != null ? 1 : 0

  account_id  = var.account_id
  bucket_name = cloudflare_r2_bucket.bucket.name
  rules       = var.lifecycle_rules
}

# R2 Data Access Logs (GA): enable in the dashboard / Workers Observability —
# no cloudflare_r2_*_access_log Terraform resource in provider 5.x yet.
# See https://developers.cloudflare.com/r2/data-access-logs/
