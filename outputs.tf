output "topic_arn" {
  value = aws_sns_topic.this.arn
}

output "topic_id" {
  value = aws_sns_topic.this.id
}

output "beginning_archive_time" {
  value = aws_sns_topic.this.beginning_archive_time
}
