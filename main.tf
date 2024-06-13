# Creates an SSM parameter for each instance with user-specific parameters. These parameters
# are monitored via the functionality deployed through the ec2_instance_user_manager module.
resource "aws_ssm_parameter" "linux_users" {
  count = length(var.instance_ids)
  name  = "/ec2_instance/${var.instance_ids[count.index]}/${var.username}"
  type  = "String"
  value = jsonencode({
    groups   = var.groups
    ssh_keys = var.ssh_keys
    sudoer   = var.sudoer
    shell    = var.shell
  })
}
