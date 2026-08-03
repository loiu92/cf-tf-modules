output "application_id" {
  description = "UUID of the Access application."
  value       = cloudflare_zero_trust_access_application.app.id
}

output "aud" {
  description = "Audience tag (CF_ACCESS_AUD). Workers verify the JWT assertion against it."
  value       = cloudflare_zero_trust_access_application.app.aud
}

output "jwks_url" {
  description = "JWKS (certs) URL for verifying Access JWTs."
  value       = "https://${var.team_domain}.cloudflareaccess.com/cdn-cgi/access/certs"
}

output "hostname" {
  description = "Protected hostname."
  value       = var.hostname
}
