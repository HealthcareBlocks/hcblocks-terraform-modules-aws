output "repo_arn" {
  value = aws_ecr_repository.this.arn
}

output "repo_url" {
  value = aws_ecr_repository.this.repository_url
}
