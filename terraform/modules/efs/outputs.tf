output "efs_file_system_id" {
  description = "The ID of the EFS File System."
  value       = aws_efs_file_system.main.id
}

output "efs_access_point_id" {
  description = "The ID of the EFS Access Point."
  value       = aws_efs_access_point.main.id
}

output "efs_security_group_id" {
  description = "The ID of the EFS Security Group."
  value       = aws_security_group.efs_sg.id
}