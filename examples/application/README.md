# Application resources

`modules/application` composes the existing R2, KV, D1 and Queues modules for
three application recipes. It owns one explicitly selected environment.

| Recipe | Resources | Worker bindings |
| --- | --- | --- |
| `auth-dashboard` | R2, KV, D1 | `DATA`, `CACHE`, `DB` |
| `api-mcp` | R2 | `DATA` |
| `queued-processing` | R2, Queues | `DATA`, `JOBS` |

Copy `terraform.tfvars.example` to `terraform.tfvars`, select a recipe and
environment, and set `CLOUDFLARE_API_TOKEN` in the shell. Then run `terraform init`
and `terraform plan`. Resource creation requires a separate explicit apply.
Never commit tokens. This example intentionally uses a local module source;
remote consumers must pin the first release containing `modules/application`.
It is not present in the existing `v0.8.0` release.

The `bindings` output contains Wrangler-compatible binding objects. Install
those objects under the matching named `env.<environment>` configuration.
Application code, auth sessions, bearer secrets, queue consumers, and deployment
remain in the app; Terraform does not create them implicitly. cf-bootstrap's
matching recipes scaffold these capabilities and their verification commands.

Switching a deployed recipe can destroy resources belonging to the previous
recipe. Review the Terraform plan and migrate data before changing a recipe.

For local checks without credentials or remote writes, run `make check` from
the repository root. Native Terraform tests mock the provider and assert
resource selection, exact names, binding contracts, and invalid-input rejection.
