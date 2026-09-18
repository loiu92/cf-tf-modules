/* wrangler-owned — Workers AI is accessed via the Worker `ai` binding (no
   discrete cloudflare_workers_ai_* resource in provider 5.x). cf-bootstrap
   emits a comment-only TF placeholder and renders the binding + /ai stub route
   when this module is selected. Tracking: Workers AI (ai binding). */
