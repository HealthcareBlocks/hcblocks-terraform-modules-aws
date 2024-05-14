output "lambda_function_arn" {
  value = aws_lambda_function.this.arn
}

output "lambda_function_invoke_arn" {
  value = aws_lambda_function.this.invoke_arn
}

output "lambda_function_name" {
  value = aws_lambda_function.this.function_name
}

output "lambda_function_version" {
  value = aws_lambda_function.this.version
}

output "lambda_iam_role" {
  value = aws_iam_role.this.name
}
