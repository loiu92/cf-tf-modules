resource "cloudflare_pipeline_sink" "sink" {
  account_id = var.account_id
  name       = var.name
  type       = "r2_data_catalog"
  format     = var.format
  schema     = { fields = [] }
  config = {
    account_id = var.account_id
    bucket     = var.bucket
    table_name = var.table_name
    token      = var.token
  }
}
