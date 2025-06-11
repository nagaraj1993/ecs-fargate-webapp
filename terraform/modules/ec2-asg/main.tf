data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
  filter {
    name = "architecture"
    values = ["x86_64"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}


# 1. Create a Security Group for EC2 instances in private subnets
resource "aws_security_group" "instance_sg" {
  name        = "${var.project_name}-instance-sg"
  description = "Allow HTTP from ALB and SSH access to instances"
  vpc_id      = var.vpc_id # Reference VPC ID from variable

  # Inbound rule: Allow HTTP traffic from the ALB's Security Group
  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_sg_id] # Reference ALB SG ID from variable
  }

  # Inbound rule: Allow SSH traffic (Restrict this heavily in production!)
  # totally not recommended. Anyone can do search for open ssh and then hack your system. Normally we can ssh into the private instance directly from the consolse itself.
#   ingress {
#     description = "Allow SSH from specific IP (e.g., your public IP)"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # WARNING: Change this to your public IP or a bastion host's SG!
#   }

  # Outbound rule: Allow all outbound traffic (will use NAT Gateway via private route table)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-instance-sg"
  }
}

# It is better use the AWS Systems Manager Session Manager - we can use this from the console directly to ssh into the ec2 instance.
# Optional: Create SSH Key Pair (if you want Terraform to manage it)
# Add provider "tls" in versions.tf in this module or root
# resource "tls_private_key" "rsa_key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }
# resource "aws_key_pair" "generated_key" {
#   key_name   = var.key_pair_name
#   public_key = tls_private_key.rsa_key.public_key_openssh
# }
# resource "local_file" "private_key" {
#   content  = tls_private_key.rsa_key.private_key_pem
#   filename = "${path.module}/${var.key_pair_name}.pem"
#   file_permission = "0600"
# }


# 2. Create a Launch Template for the Auto Scaling Group
resource "aws_launch_template" "web_app_lt" {
  name_prefix   = "${var.project_name}-web-app-"
  image_id      = var.ami_id == "" ? data.aws_ami.amazon_linux.id : var.ami_id
  instance_type = var.instance_type
#  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  # --- UPDATED USER DATA SCRIPT ---
  user_data = base64encode(<<EOF
#!/bin/bash
# Update package lists and upgrade existing packages
sudo dnf update -y  # Use dnf instead of yum for AL2023

# Install Nginx
sudo dnf install -y nginx # Use dnf install nginx for AL2023

# Enable and start Nginx service
sudo systemctl enable nginx
sudo systemctl start nginx

# Basic index.html for testing
echo "<h1>Hello from ${var.project_name} - Web App Instance!</h1>" | sudo tee /usr/share/nginx/html/index.html

# Optionally, a simple health check endpoint for /health
# echo "OK" | sudo tee /usr/share/nginx/html/health
EOF
  )
  # --- END UPDATED USER DATA SCRIPT ---

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-web-app-instance"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.project_name}-web-app-volume"
    }
  }

  tags = {
    Name = "${var.project_name}-web-app-lt"
  }
}


# 3. Create an Auto Scaling Group (ASG)
resource "aws_autoscaling_group" "web_app_asg" {
  name                      = "${var.project_name}-web-app-asg"
  vpc_zone_identifier       = var.private_subnet_ids # Reference private subnet IDs from variable
  desired_capacity          = var.asg_desired_capacity
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  health_check_type         = "ELB"
  health_check_grace_period = 300

  target_group_arns = [var.alb_target_group_arn] # Reference ALB TG ARN from variable

  launch_template {
    id      = aws_launch_template.web_app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-app-asg-instance"
    propagate_at_launch = true
  }
}