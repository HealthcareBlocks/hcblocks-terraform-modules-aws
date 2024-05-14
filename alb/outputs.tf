output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_dns" {
  value = aws_lb.this.dns_name
}

output "alb_zone_id" {
  value = aws_lb.this.zone_id
}

output "listeners" {
  description = "Map of listeners created and their attributes"
  value       = aws_lb_listener.this
}

output "listener_rules" {
  description = "Map of listeners rules created and their attributes"
  value       = aws_lb_listener_rule.this
}

output "target_groups" {
  description = "Map of target groups created and their attributes"
  value       = aws_lb_target_group.this
}

output "security_group_arn" {
  description = "Amazon Resource Name (ARN) of the security group"
  value       = aws_security_group.default.arn
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.default.id
}
