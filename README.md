# cf-tf-modules

Shared Terraform modules for Cloudflare resources, consumed by Cloudflare Workers
projects via Terragrunt.

## Consumption

Source pattern (note the **`//modules/<name>`** subpath and the pinned `ref`):

```hcl
source = "github::lucas-ruelle/cf-tf-modules//modules/r2?ref=v0.1.0"
```

The consuming project supplies the `cloudflare` provider configuration
(`api_token`, etc.) — these modules declare **only** `required_providers`
constraints and never a `provider "cloudflare" {}` block. No credentials live
in this repo.

## Modules

| Name | Purpose | Key inputs | Key outputs |
| --- | --- | --- | --- |
| `r2` | R2 bucket (+ optional lifecycle) | `name`, `location_hint`, `lifecycle_rules` | `bucket_name`, `bucket_id` |
| `kv` | Workers KV namespaces (for_each) | `namespaces` (set of titles) | `namespace_ids` (title→id) |
| `d1` | D1 databases (for_each) | `databases` (set of names) | `database_ids` (name→uuid), `database_names` |
| `queues` | Queues (for_each) | `queues` (set of names) | `queue_ids` (name→id) |
| `ai-gateway` | AI Gateway | `name`, `collect_logs`, `cache_invalidate_on_update`, … | `gateway_id` |
| `hyperdrive` | Hyperdrive config (Postgres) | `name`, `origin` ({database,host,password,port,scheme,user}) | `hyperdrive_id` |
| `dns` | DNS records (for_each) | `zone_id`, `records` (list of objects) | `record_ids` |
| `workers-domain` | Workers Custom Domain (auto-TLS/DNS) | `zone_id`, `hostname`, `service`, `environment` | `hostname` |
| `email` | Email routing (catch-all → Worker) | `zone_id`, `destination_worker`, `enabled` | `enabled` |
| `workflows` | Workers Workflow | `name`, `script_name`, `binding` | `workflow_id` |
| `zone` | Zone (prevent_destroy) | `domain` | `zone_id`, `name`, `name_servers` |

Every module takes `account_id` (string) except `dns`, `email`, and `zone`,
which are zone-scoped (`zone_id` / `domain`).

## Tagging policy

- **Semver tags on every change.** Every merge that changes any module MUST be
  followed by a tag `vX.Y.Z`.
- **Consumers pin per project**: bump `ref=?ref=vX.Y.Z` in each consuming
  repo's terragrunt/`source` line explicitly. Do not track `main` — pin a tag.
- Breaking changes to a module's variable/output signature bump the **MAJOR**.
- New optional inputs/outputs bump the **MINOR**. Internal-only changes bump
  the **PATCH**.

## Layout

```
versions.tf          # repo-level baseline pin (no provider config)
modules/<name>/
  main.tf
  variables.tf
  outputs.tf
  versions.tf        # cloudflare ~> 5.0, terraform >= 1.7
```
