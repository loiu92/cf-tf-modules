variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "databases" {
  description = "Set of D1 database names to create."
  type        = set(string)
  nullable    = false
}
