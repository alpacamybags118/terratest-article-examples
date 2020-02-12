provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

# Loading some VPC information we will need later on.
data "aws_vpc" "vpc" {
    vpc_id = var.vpc_id
}

data "aws_subnet_ids" "vpc_subnets" {
  vpc_id = var.vpc_id
}

# We are loading the base Amazon Linux 2 AMI and will run a bootstrap on top to install a sample app
data "aws_ami" "sample_app" {
    most_recent = true

    filter = {
        name = "image-ids"
        values = ["ami-062f7200baf2fa504"]
    }
}

# This is the security group we will attach to our ec2 instances. We will only allow traffic in
# from the VPC
resource "aws_security_group" "ec2_sg" {
    name = "startup-app-ec2-sg"
    description = "SG for EC2 instances for Startup App"
    vpc_id = var.vpc_id

    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# This will create our EC2 instances with the loaded AMI above
resource "aws_instance" "application" {
    count = 2

    ami = aws_ami.sample_app.id

    # Networking
    vpc_security_group_ids = [aws_security_group.ec2_sg.id]
}

# This is the security group we will attach to our load balancer. We will allow traffic
# from the public internet.
resource "aws_security_group" "alb_sg" {
    name = "startup-app-alb-sg"
    description = "SG for Load Balancer for Startup App"
    vpc_id = var.vpc_id

    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
}

# This will create the load balancer that will route traffic between our EC2s
resource "aws_lb" "app_lb" {
    name = "startup-app-lb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb_sg.arn]
    subnets = [data.aws_subnet_ids.vpc_subnets.ids]
}

# This creates the listener for the target group. It will forward traffic on port 80 to
# a target group with the EC2 instances
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tg.arn}"
  }
}

# Target group that ties the EC2 instances to the load balancer
resource "aws_lb_target_group" "tg" {
  name     = "startup-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}
