variable "data_subnet_ids" {
  type = list(string)
}

variable "data_security_group_id" {
  type = string
}

variable "snapshot_id" {
  description = "Manual snapshot kept from the Day 4 teardown"
  type        = string
  default     = "app-db-manual-1"
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}
