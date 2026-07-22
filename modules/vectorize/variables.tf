variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Vectorize index name. (Not yet managed by Terraform.)"
  type        = string
  nullable    = false
}

variable "dimensions" {
  description = "Vector dimensions. (Not yet managed by Terraform.)"
  type        = number
  default     = null
}

variable "metric" {
  description = "Distance metric. (Not yet managed by Terraform.)"
  type        = string
  default     = null
}
