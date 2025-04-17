resource "aws_sns_topic" "this" {
  archive_policy              = var.archive_policy
  content_based_deduplication = var.content_based_deduplication
  delivery_policy             = var.delivery_policy
  display_name                = var.display_name
  fifo_topic                  = var.fifo_topic
  kms_master_key_id           = var.kms_master_key_id
  name                        = var.topic_name
  tags                        = var.tags
  tracing_config              = var.tracing_config

  lambda_success_feedback_role_arn    = var.lambda_success_feedback_role_arn
  lambda_success_feedback_sample_rate = var.lambda_success_feedback_sample_rate
  lambda_failure_feedback_role_arn    = var.lambda_failure_feedback_role_arn

  sqs_success_feedback_role_arn    = var.sqs_success_feedback_role_arn
  sqs_success_feedback_sample_rate = var.sqs_success_feedback_sample_rate
  sqs_failure_feedback_role_arn    = var.sqs_failure_feedback_role_arn
}

resource "aws_sns_topic_subscription" "this" {
  for_each = { for k, v in var.subscriptions : k => v }

  confirmation_timeout_in_minutes = try(each.value.confirmation_timeout_in_minutes, null)
  delivery_policy                 = try(each.value.delivery_policy, null)
  endpoint                        = each.value.endpoint
  endpoint_auto_confirms          = try(each.value.endpoint_auto_confirms, null)
  filter_policy                   = try(each.value.filter_policy, null)
  filter_policy_scope             = try(each.value.filter_policy_scope, null)
  protocol                        = each.value.protocol
  raw_message_delivery            = try(each.value.raw_message_delivery, null)
  redrive_policy                  = try(each.value.redrive_policy, null)
  replay_policy                   = try(each.value.replay_policy, null)
  subscription_role_arn           = try(each.value.subscription_role_arn, null)
  topic_arn                       = aws_sns_topic.this.arn
}
