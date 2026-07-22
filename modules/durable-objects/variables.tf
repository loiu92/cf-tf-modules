variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Durable Object namespace name. (Not yet managed by Terraform.)"
  type        = string
  nullable    = false
}

variable "script_name" {
  description = "Owning Worker script name. (Not yet managed by Terraform.)"
  type        = string
  default     = null
}
