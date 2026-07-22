variable "zone_id" {
  description = "Cloudflare zone ID."
  type        = string
  nullable    = false
}

variable "records" {
  description = "List of DNS record objects."
  type = list(object({
    name     = string
    type     = string
    content  = string
    ttl      = optional(number, 1)
    proxied  = optional(bool, true)
    priority = optional(number)
  }))
  nullable = false
}
