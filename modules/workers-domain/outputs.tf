output "hostname" {
  description = "Configured hostname."
  value       = cloudflare_workers_custom_domain.domain.hostname
}
