# Workers Custom Domain. Auto-provisions TLS and the DNS record — do NOT also
# create a cloudflare_dns_record for this hostname (would conflict).

resource "cloudflare_workers_custom_domain" "domain" {
  account_id  = var.account_id
  zone_id     = var.zone_id
  hostname    = var.hostname
  service     = var.service
  environment = var.environment
}
