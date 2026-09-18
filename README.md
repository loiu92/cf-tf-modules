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
| `access` | Cloudflare Access (Zero Trust) email-gated application protecting a hostname | `account_id`, `hostname`, `allowed_emails`, `team_domain`, `session_duration`, `path` | `application_id`, `aud`, `jwks_url`, `hostname` |
| `email` | Email routing (catch-all → Worker) | `zone_id`, `destination_worker`, `enabled` | `enabled` |
| `workflows` | Workers Workflow | `name`, `script_name`, `binding` | `workflow_id` |
| `zone` | Zone (prevent_destroy) | `domain` | `zone_id`, `name`, `name_servers` |
| `ai-search` _(beta)_ | AI Search instance | `account_id`, `name` | `instance_id` |
| `r2-data-catalog` _(beta)_ | R2 Data Catalog on a bucket | `account_id`, `bucket_name` | `catalog_id`, `name`, `status` |
| `pipelines` | Pipeline (SQL) | `account_id`, `name`, `sql` | `pipeline_id` |
| `secrets-store` | Secrets Store | `account_id`, `name` | `store_id` |
| `containers` _(wrangler-owned)_ | Workers Containers / Sandboxes | _(none — via wrangler)_ | _(none)_ |
| `durable-objects` _(wrangler-owned)_ | DO via wrangler migrations | _(none — via wrangler)_ | _(none)_ |
| `browser-rendering` _(wrangler-owned)_ | Browser via wrangler binding | _(none — via `browser` binding)_ | _(none)_ |
| `workers-ai` _(wrangler-owned)_ | Workers AI binding | _(none — via `ai` binding)_ | _(none)_ |
| `vectorize` _(wrangler-owned)_ | Vectorize index binding | _(none — create index via wrangler)_ | _(none)_ |
| `analytics-engine` _(wrangler-owned)_ | Analytics Engine dataset binding | _(none — via wrangler)_ | _(none)_ |
| `vpc` _(unsupported)_ | Cloudflare VPC — no provider resource | `account_id` | _(none — manage via dashboard/API)_ |

Every module takes `account_id` (string) except `dns`, `email`, and `zone`
(zone-scoped via `zone_id` / `domain`). Access is account-scoped (`account_id`)
even though the protected hostname usually lives on a zone.

### Provider support notes

Modules marked **_(wrangler-owned)_** have **no** discrete Terraform resource in
the `cloudflare` provider as of `~> 5.0`. Their `main.tf` is a comment-only
placeholder; cf-bootstrap still selects them via `--modules` and renders
Wrangler bindings / stubs. **_(unsupported)_** modules are placeholders only
(not selectable in cf-bootstrap yet).

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
