output "bucket_name" {
  description = "R2 bucket this access-logs intent targets."
  value       = var.bucket_name
}

output "enabled" {
  description = "Desired Data Access Logs enabled flag (not API-enforced)."
  value       = var.enabled
}

output "status" {
  description = "Management status until a provider resource exists."
  value       = "dashboard_required"
}

output "dashboard_hint" {
  description = "Where to enable Data Access Logs today."
  value       = "Cloudflare dashboard → R2 → ${var.bucket_name} → Settings → Data Access Logs"
}
