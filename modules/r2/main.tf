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

# R2 Data Access Logs (GA): no provider resource yet. Select module
# `r2-access-logs` to record intent, or enable in the dashboard:
# https://developers.cloudflare.com/r2/buckets/data-access-logs/
