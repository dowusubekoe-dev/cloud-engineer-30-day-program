variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "app_subnet_ids" {
  type = list(string)
}

variable "public_security_group_id" {
  type = string
}

variable "app_security_group_id" {
  type = string
}

variable "ami_id" {
  description = "AMI from the hand-built launch template (Day 3)"
  type        = string
  default     = "ami-096ef200a877f36af"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "asg_min" {
  type    = number
  default = 2
}

variable "asg_max" {
  type    = number
  default = 4
}

variable "asg_desired" {
  type    = number
  default = 2
}
