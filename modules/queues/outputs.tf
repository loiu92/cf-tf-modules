output "queue_ids" {
  description = "Map of queue name → queue ID."
  value       = { for k, v in cloudflare_queue.queue : k => v.id }
}
