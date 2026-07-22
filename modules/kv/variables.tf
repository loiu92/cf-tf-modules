variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "namespaces" {
  description = "Set of KV namespace titles to create."
  type        = set(string)
  nullable    = false
}
