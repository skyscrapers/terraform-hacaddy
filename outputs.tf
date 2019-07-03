output "efs_dns_name" {
  value = aws_efs_mount_target.hacaddy_efs_target.*.dns_name
}

output "eips" {
  value = aws_eip.hacaddy_eip.*.public_ip
}

output "instance_ids" {
  value = module.hacaddy_instance.instance_ids
}

output "sg_id" {
  value = aws_security_group.sg_hacaddy.id
}
