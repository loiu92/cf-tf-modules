# R2 Data Access Logs (GA) — provider gap.
#
# There is no cloudflare_r2_*_data_access_log (or equivalent) resource in the
# Cloudflare Terraform provider 5.x, and the public OpenAPI schema has no enable
# endpoint. Turn logs on in the dashboard (bucket → Data Access Logs → Enabled),
# then view them in Workers Observability (r2 dataset).
# Docs: https://developers.cloudflare.com/r2/buckets/data-access-logs/
#
# This module records desired state so projects can declare intent and flip to a
# real resource when the provider catches up.

resource "terraform_data" "data_access_logs" {
  input = {
    account_id  = var.account_id
    bucket_name = var.bucket_name
    enabled     = var.enabled
    managed_by  = "cf-tf-modules/r2-access-logs"
    note        = "Enable Data Access Logs in the Cloudflare dashboard until a provider resource exists."
  }
}
