output "instance_id" {
  description = "AI Search instance ID (the caller-chosen name)."
  value       = cloudflare_ai_search_instance.instance.id
}
