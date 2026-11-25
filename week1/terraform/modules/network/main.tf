# Network module: rebuilds the Day 2 hand-built design under Terraform.
# VPC 10.20.0.0/16, three tiers x two AZs, IGW for the public tier,
# one NAT gateway for private-tier egress, S3 gateway endpoint on the
# app and data route tables (matches the original design exactly).

resource "aws_vpc" "w1" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "w1-vpc" }
}

# --- Subnets -------------------------------------------------------------

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.w1.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "w1-public-${count.index == 0 ? "a" : "b"}" }
}

resource "aws_subnet" "app" {
  count             = length(var.app_subnets)
  vpc_id            = aws_vpc.w1.id
  cidr_block        = var.app_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = { Name = "w1-app-${count.index == 0 ? "a" : "b"}" }
}

resource "aws_subnet" "data" {
  count             = length(var.data_subnets)
  vpc_id            = aws_vpc.w1.id
  cidr_block        = var.data_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = { Name = "w1-data-${count.index == 0 ? "a" : "b"}" }
}

# --- Internet gateway + public routing -----------------------------------

resource "aws_internet_gateway" "w1" {
  vpc_id = aws_vpc.w1.id

  tags = { Name = "w1-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.w1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.w1.id
  }

  tags = { Name = "w1-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- NAT gateway (private-tier egress, restores the Day 2 design) --------

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = { Name = "w1-nat-eip" }
}

resource "aws_nat_gateway" "w1" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = { Name = "w1-nat" }

  depends_on = [aws_internet_gateway.w1]
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.w1.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.w1.id
  }

  tags = { Name = "w1-app-rt" }
}

resource "aws_route_table_association" "app" {
  count          = length(aws_subnet.app)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app.id
}

resource "aws_route_table" "data" {
  vpc_id = aws_vpc.w1.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.w1.id
  }

  tags = { Name = "w1-data-rt" }
}

resource "aws_route_table_association" "data" {
  count          = length(aws_subnet.data)
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data.id
}

# --- S3 gateway endpoint (private tiers reach S3 without the NAT) --------

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.w1.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.app.id, aws_route_table.data.id]

  tags = { Name = "w1-s3-endpoint" }
}

# --- Security groups (Day 2 tier rules, one-directional references) ------

resource "aws_security_group" "public" {
  name        = "w1-public-sg"
  description = "Public tier: HTTPS from the internet"
  vpc_id      = aws_vpc.w1.id

  tags = { Name = "w1-public-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "public_http" {
  security_group_id = aws_security_group.public.id
  description       = "HTTP from the internet"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "public_https" {
  security_group_id = aws_security_group.public.id
  description       = "HTTPS from the internet"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "public_all" {
  security_group_id = aws_security_group.public.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "app" {
  name        = "w1-app-sg"
  description = "App tier: HTTPS only from the public tier"
  vpc_id      = aws_vpc.w1.id

  tags = { Name = "w1-app-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "app_http" {
  security_group_id            = aws_security_group.app.id
  description                  = "HTTP from the public tier (ALB)"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.public.id
}

resource "aws_vpc_security_group_ingress_rule" "app_https" {
  security_group_id            = aws_security_group.app.id
  description                  = "HTTPS from the public tier (ALB)"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.public.id
}

resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "data" {
  name        = "w1-data-sg"
  description = "Data tier: Postgres/MySQL only from the app tier"
  vpc_id      = aws_vpc.w1.id

  tags = { Name = "w1-data-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "data_postgres" {
  security_group_id            = aws_security_group.data.id
  description                  = "PostgreSQL from the app tier"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_ingress_rule" "data_mysql" {
  security_group_id            = aws_security_group.data.id
  description                  = "MySQL from the app tier"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_egress_rule" "data_all" {
  security_group_id = aws_security_group.data.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
