# D1 databases, one per name in var.databases.

resource "cloudflare_d1_database" "db" {
  for_each   = toset(var.databases)
  account_id = var.account_id
  name       = each.value
}
