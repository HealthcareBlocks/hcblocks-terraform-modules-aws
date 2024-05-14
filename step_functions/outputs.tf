output "state_machine_arn" {
  value = aws_sfn_state_machine.this.arn
}

output "state_machine_id" {
  value = aws_sfn_state_machine.this.id
}
