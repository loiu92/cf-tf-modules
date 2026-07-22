variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "name" {
  description = "AI Search instance name (used as the instance `id`)."
  type        = string
  nullable    = false
}
