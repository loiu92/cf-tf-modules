variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "queues" {
  description = "Set of queue names to create."
  type        = set(string)
  nullable    = false
}
