variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Pipeline name."
  type        = string
  nullable    = false
}

variable "sql" {
  description = "SQL definition of the pipeline."
  type        = string
  nullable    = false
}
