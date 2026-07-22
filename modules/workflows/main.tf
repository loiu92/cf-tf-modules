# Workers Workflow, owned by the Worker script in var.script_name.
# `binding` (default = name) is the workflow_name exported on the Worker env.

resource "cloudflare_workflow" "workflow" {
  account_id    = var.account_id
  script_name   = var.script_name
  class_name    = var.class_name
  workflow_name = coalesce(var.binding, var.name)
}
