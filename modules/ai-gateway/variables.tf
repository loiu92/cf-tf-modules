variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "name" {
  description = "AI Gateway ID (also used as its name)."
  type        = string
  nullable    = false
}

variable "collect_logs" {
  description = "Collect request logs."
  type        = bool
  default     = true
  nullable    = false
}

variable "cache_invalidate_on_update" {
  description = "Invalidate cache on model/content update."
  type        = bool
  default     = true
  nullable    = false
}

variable "cache_ttl" {
  description = "Cache TTL in seconds. 0 = disabled."
  type        = number
  default     = 0
  nullable    = false
}

variable "logpush" {
  description = "Enable Logpush for gateway logs."
  type        = bool
  default     = false
  nullable    = false
}

variable "rate_limiting_interval" {
  description = "Rate-limiting window in seconds. 0 = disabled."
  type        = number
  default     = 0
  nullable    = false
}

variable "rate_limiting_limit" {
  description = "Max requests in the rate-limiting window. 0 = disabled."
  type        = number
  default     = 0
  nullable    = false
}
