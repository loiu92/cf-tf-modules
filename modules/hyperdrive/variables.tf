variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Hyperdrive config name."
  type        = string
  nullable    = false
}

variable "origin" {
  description = "Origin database connection. `password` is sensitive."
  type = object({
    database = string
    host     = string
    password = string
    port     = number
    scheme   = string
    user     = string
  })
  sensitive = true
  nullable  = false
}
