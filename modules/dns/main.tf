# DNS records, one per entry in var.records. for_each keyed by name+type+content
# so multiple records on the same name are supported.

locals {
  records = {
    for r in var.records : "${r.name}|${r.type}|${r.content}" => r
  }
}

resource "cloudflare_dns_record" "record" {
  for_each = local.records

  zone_id  = var.zone_id
  name     = each.value.name
  type     = each.value.type
  content  = each.value.content
  ttl      = each.value.ttl
  proxied  = each.value.proxied
  priority = each.value.priority
}
