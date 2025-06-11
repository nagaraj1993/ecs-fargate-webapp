output "instance_security_group_id" {
  description = "The ID of the EC2 instance security group."
  value       = aws_security_group.instance_sg.id
}

output "launch_template_id" {
  description = "The ID of the EC2 launch template."
  value       = aws_launch_template.web_app_lt.id
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group."
  value       = aws_autoscaling_group.web_app_asg.name
}

output "autoscaling_group_arn" {
  description = "The ARN of the Auto Scaling Group."
  value       = aws_autoscaling_group.web_app_asg.arn
}

# If you generated a key pair, you might want an output for its file path
# output "private_key_file_path" {
#   description = "The path to the generated private key file."
#   value       = local_file.private_key.filename
#   sensitive   = true
# }