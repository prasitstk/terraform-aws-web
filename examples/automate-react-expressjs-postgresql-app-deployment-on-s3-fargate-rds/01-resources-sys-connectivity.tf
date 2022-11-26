#################
# VPC resources #
#################

resource "aws_vpc" "sys_vpc" {
  cidr_block           = var.sys_vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.sys_name}-vpc"
  }
}

resource "aws_internet_gateway" "sys_igw" {
  vpc_id = aws_vpc.sys_vpc.id
  
  tags = {
    Name = "${var.sys_name}-igw"
  }
}

resource "aws_route_table" "sys_public_rtb" {
  vpc_id = aws_vpc.sys_vpc.id
  
  tags = {
    Name = "${var.sys_name}-public-rtb"
  }
}

resource "aws_route" "sys_public_rtb_igw_r" {
  route_table_id         = aws_route_table.sys_public_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.sys_igw.id
}

locals {
  # Assign a number to each AZ letter used in public subnets
  pub_az_number = {
    a = 1
    b = 2
    c = 3
    d = 4
    e = 5
    f = 6
  }
  
  # Assign a number to each AZ letter used in private subnets
  pvt_az_number = {
    a = 7
    b = 8
    c = 9
    d = 10
    e = 11
    f = 12
  }
}

# Determine all of the available availability zones in the current AWS region.
data "aws_availability_zones" "available" {
  state = "available"
}

# This additional data source determines some additional details about each VPC, 
# including its suffix letter.
data "aws_availability_zone" "all" {
  for_each = toset(data.aws_availability_zones.available.names)
  
  name = each.key
}

resource "aws_subnet" "sys_public_subnets" {
  for_each = data.aws_availability_zone.all
  
  vpc_id                  = aws_vpc.sys_vpc.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(aws_vpc.sys_vpc.cidr_block, 4, local.pub_az_number[each.value.name_suffix])
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.sys_name}-public-subnet-${each.value.name_suffix}"
  }
}

resource "aws_route_table_association" "sys_public_subnet_rtb_assos" {
  for_each = aws_subnet.sys_public_subnets
  
  subnet_id      = each.value.id
  route_table_id = aws_route_table.sys_public_rtb.id
}

resource "aws_eip" "sys_nat_gateway_eips" {
  for_each = data.aws_availability_zone.all
  
  vpc = true
  
  tags = {
    Name = "${var.sys_name}-nat-eip-${each.value.name_suffix}"
  }
}

resource "aws_nat_gateway" "sys_nat_gateways" {
  for_each = data.aws_availability_zone.all
  
  allocation_id = aws_eip.sys_nat_gateway_eips[each.key].id
  subnet_id     = aws_subnet.sys_public_subnets[each.key].id

  tags = {
    Name = "${var.sys_name}-nat-${each.value.name_suffix}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency 
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.sys_igw]
}

resource "aws_route_table" "sys_private_rtbs" {
  for_each = data.aws_availability_zone.all
  
  vpc_id = aws_vpc.sys_vpc.id
  
  tags = {
    Name = "${var.sys_name}-private-rtb-${each.value.name_suffix}"
  }
}

resource "aws_route" "sys_private_rtb_igw_rs" {
  for_each = data.aws_availability_zone.all

  route_table_id         = aws_route_table.sys_private_rtbs[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.sys_nat_gateways[each.key].id
}

resource "aws_subnet" "sys_private_subnets" {
  for_each = data.aws_availability_zone.all
  
  vpc_id            = aws_vpc.sys_vpc.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(aws_vpc.sys_vpc.cidr_block, 4, local.pvt_az_number[each.value.name_suffix])

  tags = {
    Name = "${var.sys_name}-private-subnet-${each.value.name_suffix}"
  }
}

resource "aws_route_table_association" "sys_private_subnet_rtb_assos" {
  for_each = data.aws_availability_zone.all
  
  subnet_id      = aws_subnet.sys_private_subnets[each.key].id
  route_table_id = aws_route_table.sys_private_rtbs[each.key].id
}

resource "aws_security_group" "api_alb_sg" {
  name        = "${var.sys_name}-api-alb-sg"
  description = "Security Group for the Application Load Balancer of API"
  vpc_id      = aws_vpc.sys_vpc.id
  
  tags = {
    Name = "${var.sys_name}-api-alb-sg"
  }
}

resource "aws_security_group_rule" "api_alb_sg_public_in_http" {
  description       = "Allow all inbound traffic on the API load balancer listener port"
  security_group_id = aws_security_group.api_alb_sg.id
  type              = "ingress"
  from_port         = 80            # Allowing traffic in from port 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Allowing traffic in from all sources
}

resource "aws_security_group_rule" "api_alb_sg_public_in_https" {
  description       = "Allow all inbound traffic on the API load balancer listener port"
  security_group_id = aws_security_group.api_alb_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "api_alb_sg_all_out_public" {
  description       = "Allow outbound traffic to services on the service listener port"
  security_group_id = aws_security_group.api_alb_sg.id
  type              = "egress"
  to_port           = 0             # Allowing any outgoing port
  from_port         = 0             # Allowing any incoming port
  protocol          = "-1"          # Allowing any outgoing protocol 
  cidr_blocks       = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
}

resource "aws_security_group" "api_svc_sg" {
  name        = "${var.sys_name}-api-svc-sg"
  description = "Security Group for the Application API ECS Service"
  vpc_id      = aws_vpc.sys_vpc.id
  
  tags = {
    Name = "${var.sys_name}-api-svc-sg"
  }
}

resource "aws_security_group_rule" "api_svc_sg_alb_in_all" {
  description       = "All inbound from API load balancer"
  security_group_id = aws_security_group.api_svc_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = aws_security_group.api_alb_sg.id  # Only allowing traffic in from the load balancer security group
}

resource "aws_security_group_rule" "api_svc_sg_all_out_public" {
  security_group_id = aws_security_group.api_svc_sg.id
  type              = "egress"
  to_port           = 0     # Allowing any outgoing port
  from_port         = 0     # Allowing any incoming port
  protocol          = "-1"  # Allowing any outgoing protocol 
  cidr_blocks       = ["0.0.0.0/0"]  # Allowing traffic out to all IP addresses
}

resource "aws_security_group" "data_db_sg" {
  name        = "${var.sys_name}-data-db-sg"
  description = "Security Group for database for ${var.sys_name} application"
  vpc_id      = aws_vpc.sys_vpc.id
  
  tags = {
    Name = "${var.sys_name}-data-db-sg"
  }
}

resource "aws_security_group_rule" "data_db_sg_api_in_pg" {
  description              = "Allow inbound from ${var.sys_name}-data-db-sg"
  security_group_id        = aws_security_group.data_db_sg.id
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.api_svc_sg.id
}

resource "aws_security_group_rule" "data_db_sg_all_out_public" {
  security_group_id = aws_security_group.data_db_sg.id
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
