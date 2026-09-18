# Cloudflare Access (Zero Trust) application protecting a self-hosted hostname
# behind an email allow-list. The provider v5 resource is
# `cloudflare_zero_trust_access_application` (the legacy `cloudflare_access_*`
# names were removed); the allow policy is embedded inline in the application's
# `policies` block, which is the v5 association model (the standalone
# `cloudflare_zero_trust_access_policy` resource has no application_id link).
#
# Access entitlements are account-scoped. Prefer `account_id` over `zone_id`:
# zone-route creates (`POST /zones/.../access/apps`) commonly 403 when the
# token only has Account → Access: Apps and Policies Write/Edit.

locals {
  domain = var.path == "" ? var.hostname : "${var.hostname}${var.path}"
}

resource "cloudflare_zero_trust_access_application" "app" {
  account_id       = var.account_id
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
