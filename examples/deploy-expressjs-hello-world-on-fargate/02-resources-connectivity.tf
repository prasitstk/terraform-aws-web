#################
# VPC Resources #
#################

resource "aws_vpc" "app_vpc" {
  cidr_block           = "${var.app_vpc_cidr_block}"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "app-vpc"
  }
}

resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id
  
  tags = {
    Name = "app-igw"
  }
}

resource "aws_route_table" "app_public_rtb" {
  vpc_id = aws_vpc.app_vpc.id
  
  tags = {
    Name = "app-public-rtb"
  }
}

resource "aws_route" "app_public_rtb_igw_r" {
  route_table_id         = aws_route_table.app_public_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.app_igw.id
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

resource "aws_subnet" "app_public_subnets" {
  for_each = data.aws_availability_zone.all
  
  vpc_id                  = aws_vpc.app_vpc.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(aws_vpc.app_vpc.cidr_block, 4, local.pub_az_number[each.value.name_suffix])
  map_public_ip_on_launch = true

  tags = {
    Name = "app-public-subnet-${each.value.name_suffix}"
  }
}

resource "aws_route_table_association" "app_public_subnet_rtb_assos" {
  for_each = aws_subnet.app_public_subnets
  
  subnet_id      = each.value.id
  route_table_id = aws_route_table.app_public_rtb.id
}

resource "aws_security_group" "app_alb_sg" {
  name        = "app-alb-sg"
  description = "Security Group for the Application Load Balancer"
  vpc_id      = aws_vpc.app_vpc.id
  
  tags = {
    Name = "app-alb-sg"
  }
}

resource "aws_security_group_rule" "app_alb_sg_public_in_http" {
  description       = "Allow all inbound traffic on the load balancer listener port"
  security_group_id = aws_security_group.app_alb_sg.id
  type              = "ingress"
  from_port         = 80            # Allowing traffic in from port 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Allowing traffic in from all sources
}

resource "aws_security_group_rule" "app_alb_sg_all_out_public" {
  description       = "Allow outbound traffic to services on the service listener port"
  security_group_id = aws_security_group.app_alb_sg.id
  type              = "egress"
  to_port           = 0             # Allowing any outgoing port
  from_port         = 0             # Allowing any incoming port
  protocol          = "-1"          # Allowing any outgoing protocol 
  cidr_blocks       = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
}

resource "aws_security_group" "app_svc_sg" {
  name        = "app-svc-sg"
  description = "Security Group for the Application ECS Service"
  vpc_id      = aws_vpc.app_vpc.id
  
  tags = {
    Name = "app-svc-sg"
  }
}

resource "aws_security_group_rule" "app_svc_sg_alb_in_all" {
  description       = "All inbound from load balancer"
  security_group_id = aws_security_group.app_svc_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = aws_security_group.app_alb_sg.id  # Only allowing traffic in from the load balancer security group
}

resource "aws_security_group_rule" "app_svc_sg_all_out_public" {
  security_group_id = aws_security_group.app_svc_sg.id
  type              = "egress"
  to_port           = 0     # Allowing any outgoing port
  from_port         = 0     # Allowing any incoming port
  protocol          = "-1"  # Allowing any outgoing protocol 
  cidr_blocks       = ["0.0.0.0/0"]  # Allowing traffic out to all IP addresses
}
