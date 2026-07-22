output "record_ids" {
  description = "Map of record key (name|type|content) → record ID."
  value       = { for k, v in cloudflare_dns_record.record : k => v.id }
}
