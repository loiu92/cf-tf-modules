# Hyperdrive config. ignore_changes = all mirrors orbit so mutating the
# connection string after creation doesn't drift Terraform state.

resource "cloudflare_hyperdrive_config" "config" {
  account_id = var.account_id
  name       = var.name

  origin = {
    database = var.origin.database
    host     = var.origin.host
    password = var.origin.password
    port     = var.origin.port
    scheme   = var.origin.scheme
    user     = var.origin.user
  }

  lifecycle {
    ignore_changes = all
  }
}
