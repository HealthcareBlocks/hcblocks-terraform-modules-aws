output "frontend_instance_id" {
  value = module.instance_frontend.instance_id
}

output "amazonlinux_instance_id" {
  value = module.instance_amazonlinux.instance_id
}

output "arm64_instance_id" {
  value = module.instance_arm64.instance_id
}
