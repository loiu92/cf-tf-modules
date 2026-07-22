# R2 Data Catalog — enables the data catalog on an existing R2 bucket.
# The bucket itself must already exist (e.g. via the `r2` module).

resource "cloudflare_r2_data_catalog" "catalog" {
  account_id  = var.account_id
  bucket_name = var.bucket_name
}
