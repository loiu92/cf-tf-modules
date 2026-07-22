# Shared baseline pin. Each module under modules/ pins the cloudflare provider
# in its own versions.tf. Provider *configuration* (api_token) is supplied by
# the consuming project, never here — this repo holds no credentials.

terraform {
  required_version = ">= 1.7"
}
