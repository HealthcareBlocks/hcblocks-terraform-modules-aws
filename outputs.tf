output "instance_id" {
  value = aws_instance.this.id
}

output "private_ip" {
  value = aws_instance.this.private_ip
}

output "default_security_group" {
  description = "Returns the ID of the security group that is internally managed by this module."
  value       = aws_security_group.this.id
}
