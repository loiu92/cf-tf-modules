output "worker_name" {
  description = "Worker name matching cf-bootstrap; no guessed workers.dev URL."
  value       = var.environment == "prod" ? "${var.project}-api" : "${var.environment}-${var.project}-api"
}

output "bindings" {
  description = "Resource bindings for exactly this Wrangler environment. Secrets and application behavior are not provisioned here."
  value = merge(
    {
      r2_buckets = [{ binding = "DATA", bucket_name = module.r2.bucket_name }]
    },
    local.has_dashboard ? {
      kv_namespaces = [{ binding = "CACHE", id = module.kv[0].namespace_ids["${local.prefix}-cache"] }]
      d1_databases  = [{ binding = "DB", database_name = local.prefix, database_id = module.d1[0].database_ids[local.prefix] }]
    } : {},
    local.has_queue ? {
      queues = {
        producers = [{ binding = "JOBS", queue = "${local.prefix}-jobs" }]
        consumers = [{ queue = "${local.prefix}-jobs", max_batch_size = 10 }]
      }
    } : {},
  )
}

output "recipe" {
  description = "The selected application recipe."
  value       = var.recipe
}
