# Queues, one per name in var.queues.

resource "cloudflare_queue" "queue" {
  for_each   = toset(var.queues)
  account_id = var.account_id
  queue_name = each.value
}
