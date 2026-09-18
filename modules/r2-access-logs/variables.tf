variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "bucket_name" {
  description = "R2 bucket name to enable Data Access Logs on (dashboard until provider support)."
  type        = string
  nullable    = false
}

variable "enabled" {
  description = "Desired Data Access Logs state. Recorded for intent; not applied via API yet."
  type        = bool
  default     = true
  nullable    = false
}
