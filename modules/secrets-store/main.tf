# Cloudflare Secrets Store. Creates a store (a named container for secrets).
# Individual secrets are managed via `cloudflare_secrets_store_secret`.

resource "cloudflare_secrets_store" "store" {
  account_id = var.account_id
  name       = var.name
}
