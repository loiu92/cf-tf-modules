# D1 databases, one per name in var.databases.

resource "cloudflare_d1_database" "db" {
  for_each   = toset(var.databases)
  account_id = var.account_id
  name       = each.value

  # Provider/API send null for read_replication on update and Cloudflare
  # rejects it (400: Expected object, received null). Keep the live value.
  lifecycle {
    ignore_changes = [read_replication]
  }
}
