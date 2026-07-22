output "catalog_id" {
  description = "R2 Data Catalog ID."
  value       = cloudflare_r2_data_catalog.catalog.id
}

output "name" {
  description = "R2 Data Catalog name."
  value       = cloudflare_r2_data_catalog.catalog.name
}

output "status" {
  description = "R2 Data Catalog status."
  value       = cloudflare_r2_data_catalog.catalog.status
}
