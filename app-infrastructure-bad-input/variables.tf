variable "vpc_id" {
  description = "The ID of the VPC you wish to associate with the resources created by this module."
  type        = string
}

variable "private_subnet_ids" {
  description = "ID of the private subnet(s) in the VPC you wish to put your site in"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "ID of the public subnet(s) in the VPC you wish to put your site in"
  type        = list(string)
}

variable "route_53_zone_name" {
  description = "The name of the Route 53 zone you wish to put your site URL in"
  type        = string
}

variable "site_url" {
  description = "The URL for your site"
  type        = string
}


