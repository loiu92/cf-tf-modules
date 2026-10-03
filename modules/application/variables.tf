variable "account_id" {
  description = "Cloudflare account ID. Provider credentials belong to the consuming project."
  type        = string
  nullable    = false
}

variable "project" {
  description = "Project name, matching the cf-bootstrap project."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,31}$", var.project))
    error_message = "project must start with a lowercase letter and contain at most 32 lowercase letters, digits, or hyphens so environment-specific resource names fit Cloudflare limits."
  }
}

variable "environment" {
  description = "One explicit environment. Instantiate this module separately for each selected environment."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,19}$", var.environment))
    error_message = "environment must start with a lowercase letter and contain at most 20 lowercase letters, digits, or hyphens."
  }
}

variable "recipe" {
  description = "A supported application resource composition. Application authentication and Worker code are supplied by cf-bootstrap."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["auth-dashboard", "api-mcp", "queued-processing"], var.recipe)
    error_message = "recipe must be auth-dashboard, api-mcp, or queued-processing."
  }
}
