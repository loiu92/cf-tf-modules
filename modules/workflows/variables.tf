variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Workflow display name."
  type        = string
  nullable    = false
}

variable "script_name" {
  description = "Name of the Worker script that owns (defines) this workflow."
  type        = string
  nullable    = false
}

variable "binding" {
  description = "Workflow binding name (workflow_name on the Worker). Defaults to the workflow name."
  type        = string
  default     = null
}

variable "class_name" {
  description = "Workflow class name exported by the Worker script (e.g. MyWorkflow)."
  type        = string
  default     = "Workflow"
  nullable    = false
}
