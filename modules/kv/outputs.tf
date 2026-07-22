output "namespace_ids" {
  description = "Map of KV namespace title → namespace ID."
  value       = { for k, v in cloudflare_workers_kv_namespace.kv : k => v.id }
}
