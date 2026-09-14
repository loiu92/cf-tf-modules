/* wrangler-owned — Durable Object namespaces are created via Worker script
   migrations (wrangler.jsonc `migrations` + class exports) or the dashboard/API.
   No standalone `cloudflare_durable_object_namespace` resource exists in the
   cloudflare Terraform provider 5.x. cf-bootstrap emits a comment-only TF
   placeholder and renders DO bindings into wrangler.jsonc when this module is
   selected. Tracking: Durable Objects (cloudflare_durable_object_namespace). */
