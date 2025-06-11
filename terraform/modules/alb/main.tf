resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP/HTTPS access to ALB"
  vpc_id      = var.vpc_id

  # Inbound rule for HTTP (port 80) from anywhere
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound rule for HTTPS (port 443) from anywhere (if you plan to use HTTPS)
  # ingress {
  #   description = "Allow HTTPS from anywhere"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # Outbound rule: ALBs typically need to connect to target groups
  # allowing all egress is usually fine for ALBs and for now but usually it should send the request or forward it to the port your application is listeing to
  # Like this:
  # egress {
  #   description     = "Allow outbound to web app instances on port 80"
  #   from_port       = 80
  #   to_port         = 80
  #   protocol        = "tcp"
  #   security_groups = [var.instance_security_group_id] # ONLY to your EC2 instances' SG
  #   }

  # But fine for now:
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # can outbound anywhere
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_lb" "main_alb" {
  name               = "${var.project_name}-alb"
  internal           = false # Set to true for internal load balancer
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id] # Attach the ALB's security group

  # Attach to BOTH public subnets for high availability
  subnets = [
    var.public_subnet_ids[0],
    var.public_subnet_ids[1]
  ]

  enable_deletion_protection = false # Set to true in production!

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "web_app_tg" {
  name     = "${var.project_name}-web-app-tg"
  port     = 80 # The port your application listens on the EC2 instances
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Health check configuration (adjust as per your application's health endpoint)
  health_check {
    path                = "/" # Default health check path
    protocol            = "HTTP"
    port                = "traffic-port" # Use the port defined above (80)
    interval            = 30             # Check every 30 seconds
    timeout             = 5              # Timeout after 5 seconds
    healthy_threshold   = 2              # 2 successful checks to be healthy
    unhealthy_threshold = 2              # 2 failed checks to be unhealthy
    matcher             = "200-299"      # Expect HTTP 2xx response
  }

  # Ensure the security group for your instances allows traffic from the ALB
  # This implies your instances' security group will need an ingress rule allowing traffic
  # from the ALB's security group. We will add this later when creating instances.

  tags = {
    Name = "${var.project_name}-web-app-tg"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.main_alb.arn # Attach to the main ALB
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_app_tg.arn # Forward traffic to the target group
  }

  tags = {
    Name = "${var.project_name}-http-listener"
  }
}

# Optional: Add HTTPS listener if you have an SSL certificate
# resource "aws_lb_listener" "https_listener" {
#   load_balancer_arn = aws_lb.main_alb.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08" # Or a more recent one
#   certificate_arn   = "arn:aws:acm:REGION:ACCOUNT_ID:certificate/CERTIFICATE_ID" # REPLACE with your ACM certificate ARN

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web_app_tg.arn
#   }
#   tags = {
#     Name = "${var.project_name}-https-listener"
#   }
# }