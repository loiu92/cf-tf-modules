mock_provider "cloudflare" {}

variables {
  account_id     = "acc"
  hostname       = "mcp.example.com"
  allowed_emails = ["a@example.com"]
  team_domain    = "team"
}

run "defaults_unchanged" {
  command = plan
  assert {
    condition     = length(cloudflare_zero_trust_access_application.app.policies) == 1
    error_message = "default must keep one email policy"
  }
  assert {
    condition     = cloudflare_zero_trust_access_application.app.oauth_configuration == null
    error_message = "oauth must be off by default"
  }
}

run "oauth_and_service_tokens" {
  command = plan
  variables {
    allow_service_tokens = true
    managed_oauth        = { allowed_redirect_uris = ["https://claude.ai/api/mcp/auth_callback"] }
  }
  assert {
    condition     = cloudflare_zero_trust_access_application.app.policies[1].decision == "non_identity"
    error_message = "service token policy missing"
  }
  assert {
    condition     = cloudflare_zero_trust_access_application.app.oauth_configuration.enabled == true && cloudflare_zero_trust_access_application.app.oauth_configuration.grant.access_token_lifetime == "15m"
    error_message = "oauth config wrong"
  }
  assert {
    condition     = cloudflare_zero_trust_access_application.app.oauth_configuration.dynamic_client_registration.allowed_uris[0] == "https://claude.ai/api/mcp/auth_callback"
    error_message = "redirect uris wrong"
  }
}

run "oauth_rejects_path_scope" {
  command = plan
  variables {
    path          = "/mcp"
    managed_oauth = { allowed_redirect_uris = ["https://claude.ai/api/mcp/auth_callback"] }
  }
  expect_failures = [
    cloudflare_zero_trust_access_application.app,
  ]
}
