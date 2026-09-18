/* wrangler-owned — Workers Containers / Sandboxes have no Terraform resource in
   cloudflare provider 5.x. cf-bootstrap emits a comment-only TF placeholder and
   renders a Container class + Dockerfile + wrangler `containers` config when
   this module is selected. Create/manage via wrangler / dashboard.
   Tracking: Workers Containers (cloudflare_container_*). */
