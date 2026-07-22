variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "domain" {
  description = "Apex domain (zone) to add, e.g. example.com."
  type        = string
  nullable    = false
}
