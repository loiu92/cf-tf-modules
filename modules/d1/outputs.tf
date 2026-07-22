output "database_ids" {
  description = "Map of D1 database name → UUID."
  value       = { for k, v in cloudflare_d1_database.db : k => v.id }
}

output "database_names" {
  description = "Set of created D1 database names."
  value       = keys(cloudflare_d1_database.db)
}
