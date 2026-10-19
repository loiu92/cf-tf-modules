variable "account_id" {
  description = "Cloudflare account ID (Access apps are account-scoped)."
  type        = string
  nullable    = false
}

variable "hostname" {
  description = "Fully-qualified hostname to protect, e.g. app.example.com."
  type        = string
  nullable    = false
}

variable "path" {
  description = "Optional path appended to hostname to scope the app, e.g. /admin. Defaults to the whole hostname. Must be empty when managed_oauth is set (Cloudflare rejects path + OAuth)."
  type        = string
  default     = ""
}

variable "allowed_emails" {
  description = "Set of email addresses allow-listed by the Access policy."
  type        = set(string)
  default     = []
}

variable "session_duration" {
  description = "Access token lifetime (Go duration format, e.g. 24h or 2h45m)."
  type        = string
  default     = "24h"
}

variable "team_domain" {
  description = "Cloudflare Zero Trust team name (the <team> in <team>.cloudflareaccess.com). Used to derive the JWKS URL."
  type        = string
  nullable    = false
}

variable "managed_oauth" {
  description = <<-EOT
    Optional Access Managed OAuth: Access acts as the OAuth 2.0 authorization
    server for the app (RFC 8414/9728 discovery, dynamic client registration,
    PKCE) — e.g. for remote MCP servers. null (default) = disabled, today's
    behaviour.
  EOT
  type = object({
    access_token_lifetime = optional(string, "15m")
    session_duration      = optional(string, "336h")
    dcr_enabled           = optional(bool, true)
    allow_localhost       = optional(bool, true)
    allow_loopback        = optional(bool, true)
    allowed_redirect_uris = optional(list(string), [])
  })
  default = null
}

variable "allow_service_tokens" {
  description = "Add a Service Auth (non_identity) policy accepting any valid service token of the account. The origin must authorize the token's common_name itself (default deny)."
  type        = bool
  default     = false
}
