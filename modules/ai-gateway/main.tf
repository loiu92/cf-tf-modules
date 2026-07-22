# AI Gateway with logging and caching defaults mirroring orbit.

resource "cloudflare_ai_gateway" "gateway" {
  account_id                 = var.account_id
  id                         = var.name
  collect_logs               = var.collect_logs
  cache_invalidate_on_update = var.cache_invalidate_on_update
  cache_ttl                  = var.cache_ttl
  logpush                    = var.logpush
  rate_limiting_interval     = var.rate_limiting_interval
  rate_limiting_limit        = var.rate_limiting_limit
}
