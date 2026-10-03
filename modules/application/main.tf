locals {
  prefix        = "${var.project}-${var.environment}"
  has_dashboard = var.recipe == "auth-dashboard"
  has_queue     = var.recipe == "queued-processing"
}

# Compose existing modules so resource behavior and provider ownership stay shared.
module "r2" {
  source     = "../r2"
  account_id = var.account_id
  name       = "${local.prefix}-data"
}

module "kv" {
  count      = local.has_dashboard ? 1 : 0
  source     = "../kv"
  account_id = var.account_id
  namespaces = ["${local.prefix}-cache", "${local.prefix}-sessions"]
}

module "d1" {
  count      = local.has_dashboard ? 1 : 0
  source     = "../d1"
  account_id = var.account_id
  databases  = [local.prefix]
}

module "queues" {
  count      = local.has_queue ? 1 : 0
  source     = "../queues"
  account_id = var.account_id
  queues     = ["${local.prefix}-jobs"]
}
