# Workers KV namespaces, one per title in var.namespaces.

resource "cloudflare_workers_kv_namespace" "kv" {
  for_each   = toset(var.namespaces)
  account_id = var.account_id
  title      = each.value
}
