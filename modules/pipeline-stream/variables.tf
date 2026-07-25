variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Pipeline stream name."
  type        = string
  nullable    = false
}

variable "format" {
  description = "Stream format."
  type        = object({ type = string })
  default     = { type = "json" }
}

variable "fields" {
  description = "Stream schema fields."
  type = list(object({
    name     = string
    type     = string
    required = optional(bool, false)
  }))
  default = []
}

variable "worker_binding_enabled" {
  description = "Enable Worker binding ingestion."
  type        = bool
  default     = true
}

variable "http_enabled" {
  description = "Enable public HTTP ingestion (default off)."
  type        = bool
  default     = false
}
