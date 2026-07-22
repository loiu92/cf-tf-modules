variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "bucket_name" {
  description = "Name of the R2 bucket to enable the data catalog on."
  type        = string
  nullable    = false
}
