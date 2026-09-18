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
  description = "Optional path appended to hostname to scope the app, e.g. /admin. Defaults to the whole hostname."
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
