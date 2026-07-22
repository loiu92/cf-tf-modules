# AI Search instance. The Cloudflare provider exposes this as
# `cloudflare_ai_search_instance`; the required `id` attribute is the
# caller-chosen instance name and is also the primary identifier.

resource "cloudflare_ai_search_instance" "instance" {
  account_id = var.account_id
  id         = var.name
}
