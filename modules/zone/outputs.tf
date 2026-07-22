output "zone_id" {
  description = "Zone ID."
  value       = cloudflare_zone.zone.id
}

output "name" {
  description = "Zone name (apex domain)."
  value       = cloudflare_zone.zone.name
}

output "name_servers" {
  description = "Assigned nameservers."
  value       = cloudflare_zone.zone.name_servers
}
