provider "aws" {
  version = "~> 2.0"
  region  = "us-east-2"
}

# Loading some VPC information we will need later on.
data "aws_vpc" "vpc" {
  id = var.vpc_id
}

# We are loading the base Amazon Linux 2 AMI and will run a bootstrap on top to install a sample app
data "aws_ami" "sample_app" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "image-id"
    values = ["ami-0e38b48473ea57778"]
  }
}

# This is the security group we will attach to our ec2 instances. We will only allow traffic in
# from the VPC
resource "aws_security_group" "ec2_sg" {
  name        = "startup-app-ec2-sg"
  description = "SG for EC2 instances for Startup App"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# This will create our EC2 instances with the loaded AMI above
resource "aws_instance" "application" {
  count                = 2
  iam_instance_profile = aws_iam_instance_profile.profile.name

  ami = data.aws_ami.sample_app.id

  instance_type                        = "t3a.micro"
  tenancy                              = "default"
  instance_initiated_shutdown_behavior = "stop"

  ebs_optimized = true

  root_block_device {
    volume_type = "standard"
    volume_size = "10"
  }

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id              = var.private_subnet_ids[0]
}

resource "aws_iam_instance_profile" "profile" {
  name = "startup-app-profile"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name = "startup-app-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

# This is the security group we will attach to our load balancer. We will allow traffic
# from the public internet.
resource "aws_security_group" "alb_sg" {
  name        = "startup-app-alb-sg"
  description = "SG for Load Balancer for Startup App"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# This will create the load balancer that will route traffic between our EC2s
resource "aws_lb" "app_lb" {
  name               = "startup-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids
}

# This creates the listener for the target group. It will forward traffic on port 80 to
# a target group with the EC2 instances
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Target group that ties the EC2 instances to the load balancer
resource "aws_lb_target_group" "tg" {
  name     = "startup-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

# This loads the Route 53 zone based on the provided zone name
data "aws_route53_zone" "zone" {
  name = var.route_53_zone_name
}

# This will create an alias record that points your site URL to the load balancer
resource "aws_route53_record" "site" {
  zone_id = data.aws_route53_zone.zone.id
  name    = var.site_url
  type    = "A"

  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = false
  }
}
