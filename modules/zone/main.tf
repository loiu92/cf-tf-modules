# Cloudflare zone. prevent_destroy guards against accidental deletion of a zone
# (which would orphan DNS records and routing).

resource "cloudflare_zone" "zone" {
  account = {
    id = var.account_id
  }
  name = var.domain

  lifecycle {
    prevent_destroy = true
  }
}
