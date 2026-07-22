variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Container deployment name. (Not yet managed by Terraform.)"
  type        = string
  nullable    = false
}

variable "image" {
  description = "Container image reference. (Not yet managed by Terraform.)"
  type        = string
  default     = null
}
