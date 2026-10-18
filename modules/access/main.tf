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

  email_policy = {
    name       = "allow-emails"
    decision   = "allow"
    precedence = 1
    include = [
      for email in var.allowed_emails :
      { email = { email = email } }
    ]
  }

  # Service Auth: Access validates CF-Access-Client-Id/-Secret at the edge and
  # forwards a JWT whose common_name is the client id. Any valid token passes
  # here — binding a token to a user/scope is the origin's job.
  service_token_policy = {
    name       = "allow-service-tokens"
    decision   = "non_identity"
    precedence = 2
    include    = [{ any_valid_service_token = {} }]
  }
}

resource "cloudflare_zero_trust_access_application" "app" {
  account_id       = var.account_id
  name             = var.hostname
  domain           = local.domain
  type             = "self_hosted"
  session_duration = var.session_duration

  policies = concat([local.email_policy], var.allow_service_tokens ? [local.service_token_policy] : [])

  oauth_configuration = var.managed_oauth == null ? null : {
    enabled = true
    grant = {
      access_token_lifetime = var.managed_oauth.access_token_lifetime
      session_duration      = var.managed_oauth.session_duration
    }
    dynamic_client_registration = {
      enabled                = var.managed_oauth.dcr_enabled
      allow_any_on_localhost = var.managed_oauth.allow_localhost
      allow_any_on_loopback  = var.managed_oauth.allow_loopback
      allowed_uris           = var.managed_oauth.allowed_redirect_uris
    }
  }
}
