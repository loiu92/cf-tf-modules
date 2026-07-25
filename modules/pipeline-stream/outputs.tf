output "stream_id" {
  description = "Pipeline stream ID (use in wrangler [[pipelines]] stream = ...)."
  value       = cloudflare_pipeline_stream.stream.id
}

output "endpoint" {
  description = "Stream HTTP endpoint (unused when HTTP is disabled)."
  value       = cloudflare_pipeline_stream.stream.endpoint
}
