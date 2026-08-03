# Cloudflare Access (Zero Trust) application protecting a self-hosted hostname
# behind an email allow-list. The provider v5 resource is
# `cloudflare_zero_trust_access_application` (the legacy `cloudflare_access_*`
# names were removed); the allow policy is embedded inline in the application's
# `policies` block, which is the v5 association model (the standalone
# `cloudflare_zero_trust_access_policy` resource has no application_id link).
#
# The application is zone-scoped via zone_id (mutually exclusive with
# account_id on this resource). The audience tag (`aud`) is exported so Workers
# can verify the incoming cf-access-jwt-assertion.

locals {
  domain = var.path == "" ? var.hostname : "${var.hostname}${var.path}"
}

resource "cloudflare_zero_trust_access_application" "app" {
  zone_id          = var.zone_id
  name             = var.hostname
  domain           = local.domain
  type             = "self_hosted"
  session_duration = var.session_duration

  policies = [
    {
      name       = "allow-emails"
      decision   = "allow"
      precedence = 1
      include = [
        for email in var.allowed_emails :
        { email = { email = email } }
      ]
    }
  ]
}
