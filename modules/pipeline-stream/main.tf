resource "cloudflare_pipeline_stream" "stream" {
  account_id = var.account_id
  name       = var.name
  format     = var.format
  schema     = { fields = var.fields }
  http = {
    enabled        = var.http_enabled
    authentication = false
    cors           = {}
  }
  worker_binding = {
    enabled = var.worker_binding_enabled
  }
}
