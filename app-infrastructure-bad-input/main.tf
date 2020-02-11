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

# This is the security group we will attach to our ec2 instances. We will only allow traffic
# from the VPC
resource "aws_security_group" "alb_sg" {

}

# This will create our EC2 instances with the loaded AMI above
resource "aws_instance" "application" {
    count = 2

    ami = aws_ami.sample_app.id
}

# This is the security group we will attach to our load balancer. We will allow traffic
# from the public internet.
resource "aws_security_group" "alb_sg" {

}

# This will create the load balancer that will route traffic between our EC2s
resource "aws_lb" "app_lb" {
    name = "startup-app-lb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb_sg.arn]
    subnets = []
}
