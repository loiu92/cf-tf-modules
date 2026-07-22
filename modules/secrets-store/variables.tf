variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Secrets Store name."
  type        = string
  nullable    = false
}
