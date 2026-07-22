# Email routing: enable routing on the zone and add a catch-all rule that
# forwards to a Worker. Optional additional rules can be passed in var.rules.
# In cloudflare provider v5, `matchers` and `actions` are list attributes.

resource "cloudflare_email_routing_settings" "settings" {
  count   = var.enabled ? 1 : 0
  zone_id = var.zone_id
}

resource "cloudflare_email_routing_rule" "catch_all" {
  count   = var.enabled && var.destination_worker != "" ? 1 : 0
  zone_id = var.zone_id
  name    = "catch-all"

  matchers = [{ type = "all" }]
  actions = [{
    type  = "worker"
    value = [var.destination_worker]
  }]
}

resource "cloudflare_email_routing_rule" "custom" {
  for_each = {
    for r in var.rules : "${r.name}|${r.matcher_type}|${coalesce(r.matcher_value, "")}" => r
  }

  zone_id = var.zone_id
  name    = each.value.name

  matchers = [{
    type  = each.value.matcher_type
    value = each.value.matcher_type == "all" ? null : each.value.matcher_value
  }]
  actions = [{
    type  = each.value.action_type
    value = each.value.action_value
  }]
}
