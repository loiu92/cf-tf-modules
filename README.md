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
| `ai-search` _(beta)_ | AI Search instance | `account_id`, `name` | `instance_id` |
| `r2-data-catalog` _(beta)_ | R2 Data Catalog on a bucket | `account_id`, `bucket_name` | `catalog_id`, `name`, `status` |
| `pipelines` | Pipeline (SQL) | `account_id`, `name`, `sql` | `pipeline_id` |
| `secrets-store` | Secrets Store | `account_id`, `name` | `store_id` |
| `containers` _(unsupported)_ | Workers Containers — no provider resource | `account_id`, `name`, `image` | _(none — manage via dashboard/API)_ |
| `durable-objects` _(unsupported)_ | DO namespace — no standalone resource | `account_id`, `name`, `script_name` | _(none — via workers_script migrations)_ |
| `browser-rendering` _(unsupported)_ | Browser Rendering — dashboard-only | `account_id` | _(none — via `browser` binding)_ |
| `workers-ai` _(unsupported)_ | Workers AI — no discrete resource | `account_id` | _(none — via `ai` binding)_ |
| `vectorize` _(unsupported)_ | Vectorize index — no provider resource | `account_id`, `name`, `dimensions`, `metric` | _(none — via wrangler/dashboard)_ |
| `analytics-engine` _(unsupported)_ | Analytics Engine — no resource | `account_id` | _(none — via `analytics_engine` binding)_ |
| `vpc` _(unsupported)_ | Cloudflare VPC — no provider resource | `account_id` | _(none — manage via dashboard/API)_ |

Every module takes `account_id` (string) except `dns`, `email`, and `zone`,
which are zone-scoped (`zone_id` / `domain`).

### Provider support notes

Modules marked **_(unsupported)_** target Cloudflare services that have **no
Terraform resource in the `cloudflare` provider as of `~> 5.0`** (verified
against the provider schema). Their `main.tf` contains only a `/* NOT YET
SUPPORTED ... */` comment and documents the dashboard/API/wrangler alternative;
their `variables.tf`/`outputs.tf` are kept as empty placeholders so the module
directory exists and the signature is stable. Tracking resource names are
noted in each module's `main.tf`.

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
