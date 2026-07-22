variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "name" {
  description = "R2 bucket name."
  type        = string
  nullable    = false
}

variable "location_hint" {
  description = "Bucket location hint."
  type        = string
  default     = "eeur"
  nullable    = false
}

variable "lifecycle_rules" {
  description = "Optional lifecycle rules. When null, no lifecycle resource is created."
  type        = any
  default     = null
}
