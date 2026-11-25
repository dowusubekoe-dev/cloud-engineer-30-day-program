variable "vpc_cidr" {
  description = "CIDR block for the Week 1 lab VPC (Day 2 design)"
  type        = string
  default     = "10.20.0.0/16"
}

variable "azs" {
  description = "Availability zones for the two-AZ layout"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "Public tier CIDRs, one per AZ"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "app_subnets" {
  description = "App (private) tier CIDRs, one per AZ"
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "data_subnets" {
  description = "Data (private) tier CIDRs, one per AZ"
  type        = list(string)
  default     = ["10.20.21.0/24", "10.20.22.0/24"]
}
