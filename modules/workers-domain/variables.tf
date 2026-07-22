variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "zone_id" {
  description = "Cloudflare zone ID for the hostname."
  type        = string
  nullable    = false
}

variable "hostname" {
  description = "Fully-qualified hostname, e.g. app.example.com."
  type        = string
  nullable    = false
}

variable "service" {
  description = "Worker (service) name to route the hostname to."
  type        = string
  nullable    = false
}

variable "environment" {
  description = "Worker environment. Defaults to production."
  type        = string
  default     = "production"
  nullable    = false
}
