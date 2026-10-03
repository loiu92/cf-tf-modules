mock_provider "cloudflare" {}

variables {
  account_id  = "11111111111111111111111111111111"
  project     = "example"
  environment = "test"
}

run "authenticated_dashboard" {
  command = plan
  variables { recipe = "auth-dashboard" }

  assert {
    condition     = length(module.kv) == 1 && length(module.d1) == 1 && length(module.queues) == 0
    error_message = "The dashboard must select D1 and KV without queues."
  }
  assert {
    condition     = output.worker_name == "test-example-api" && output.bindings.d1_databases[0].database_name == "example-test"
    error_message = "Dashboard names must match the explicitly selected environment."
  }
}

run "api_mcp" {
  command = plan
  variables {
    recipe      = "api-mcp"
    environment = "prod"
  }

  assert {
    condition     = length(module.kv) == 0 && length(module.d1) == 0 && length(module.queues) == 0
    error_message = "API + MCP must avoid unrelated infrastructure."
  }
  assert {
    condition     = output.worker_name == "example-api" && length(keys(output.bindings)) == 1
    error_message = "Production must use the existing Worker name and only the R2 binding."
  }
}

run "queued_processing" {
  command = plan
  variables { recipe = "queued-processing" }

  assert {
    condition     = length(module.queues) == 1 && length(module.kv) == 0 && length(module.d1) == 0
    error_message = "Queued processing must select the queue and exclude dashboard resources."
  }
  assert {
    condition     = output.bindings.queues.producers[0].binding == "JOBS" && output.bindings.queues.producers[0].queue == "example-test-jobs" && output.bindings.queues.consumers[0].queue == "example-test-jobs"
    error_message = "Producer and consumer must use the same environment-specific queue."
  }
}

run "reject_unknown_recipe" {
  command = plan
  variables { recipe = "unreviewed-shape" }
  expect_failures = [var.recipe]
}

run "reject_invalid_environment" {
  command = plan
  variables {
    recipe      = "api-mcp"
    environment = "../../other"
  }
  expect_failures = [var.environment]
}
