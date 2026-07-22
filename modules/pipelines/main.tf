# Cloudflare Pipeline. A pipeline is defined by a SQL query; the provider
# resource is `cloudflare_pipeline`.

resource "cloudflare_pipeline" "pipeline" {
  account_id = var.account_id
  name       = var.name
  sql        = var.sql
}
