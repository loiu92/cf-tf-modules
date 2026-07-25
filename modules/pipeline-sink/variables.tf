variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Pipeline sink name."
  type        = string
  nullable    = false
}

variable "bucket" {
  description = "R2 bucket name."
  type        = string
  nullable    = false
}

variable "table_name" {
  description = "Iceberg table name."
  type        = string
  nullable    = false
}

variable "token" {
  description = "Scoped sink API token."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "format" {
  description = "Sink format."
  type        = object({ type = string })
  default = {
    type = "parquet"
  }
}
