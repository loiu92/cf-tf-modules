variable "zone_id" {
  description = "Cloudflare zone ID."
  type        = string
  nullable    = false
}

variable "enabled" {
  description = "Enable email routing on the zone."
  type        = bool
  default     = true
  nullable    = false
}

variable "destination_worker" {
  description = "Worker name to receive the catch-all rule. Empty disables the catch-all."
  type        = string
  default     = ""
  nullable    = false
}

variable "rules" {
  description = "Optional additional routing rules."
  type = list(object({
    name          = string
    matcher_type  = string
    matcher_value = optional(string)
    action_type   = string
    action_value  = optional(list(string))
  }))
  default = []
}
