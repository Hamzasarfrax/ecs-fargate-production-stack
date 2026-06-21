

# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "6.43.0"
#     }
#   }
# }

# ---------------- VPC ----------------

data "aws_region" "current" {}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.tags, {
    Name        = "${var.name}-vpc"
    Environment = var.environment
  })
}

# ---------------- PUBLIC SUBNETS ----------------

resource "aws_subnet" "public_subnet" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name        = "${var.name}-${each.key}"
    Environment = var.environment
    Tier        = "public"
  })
}

# ---------------- PRIVATE SUBNETS ----------------

resource "aws_subnet" "private_subnet" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name        = "${var.name}-${each.key}"
    Environment = var.environment
    Tier        = "private"
  })
}

# ---------------- INTERNET GATEWAY ----------------

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name        = "${var.name}-igw"
    Environment = var.environment
  })
}

# ---------------- LOCALS ----------------

locals {

  single_nat = var.nat_gateway_strategy == "single" ? {
    primary = values(aws_subnet.public_subnet)[0]
  } : {}

  nat_gateway_subnets = var.nat_gateway_strategy == "one_per_az" ? aws_subnet.public_subnet : local.single_nat

  private_nat_gateway_key = {
    for key, subnet in aws_subnet.private_subnet :
    key => var.nat_gateway_strategy == "single" ? "primary" : replace(key, "private", "public")
  }
}

# ---------------- EIP ----------------

resource "aws_eip" "nat" {
  for_each = var.nat_gateway_strategy == "none" ? {} : local.nat_gateway_subnets

  domain = "vpc"

  tags = merge(var.tags, {
    Name        = "${var.name}-${each.key}-eip"
    Environment = var.environment
  })

  depends_on = [aws_internet_gateway.gw]
}

# ---------------- NAT GATEWAY ----------------

resource "aws_nat_gateway" "nat_gateway" {
  for_each = var.nat_gateway_strategy == "none" ? {} : local.nat_gateway_subnets

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = merge(var.tags, {
    Name        = "${var.name}-${each.key}-nat"
    Environment = var.environment
  })

  depends_on = [aws_internet_gateway.gw]
}

# ---------------- PUBLIC ROUTE TABLE ----------------

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(var.tags, {
    Name        = "${var.name}-public-rt"
    Environment = var.environment
  })
}

# ---------------- PUBLIC ROUTE TABLE ASSOCIATION ----------------

resource "aws_route_table_association" "attach_public_subnet" {
  for_each = aws_subnet.public_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

# ---------------- PRIVATE ROUTE TABLE ----------------

resource "aws_route_table" "private_route_table" {
  for_each = aws_subnet.private_subnet

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.nat_gateway_strategy == "none" ? [] : [1]

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat_gateway[local.private_nat_gateway_key[each.key]].id
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.name}-${each.key}-private-rt"
    Environment = var.environment
  })
}

# ---------------- PRIVATE ROUTE TABLE ASSOCIATION ----------------

resource "aws_route_table_association" "attach_private_subnet" {
  for_each = aws_subnet.private_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_route_table[each.key].id
}

# ---------------- VPC ENDPOINTS ----------------

resource "aws_security_group" "vpc_endpoints" {
  count = var.enable_vpc_endpoints ? 1 : 0

  name        = "${var.name}-vpce-sg"
  description = "Allow private subnet workloads to use interface VPC endpoints over HTTPS."
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  tags = merge(var.tags, {
    Name        = "${var.name}-vpce-sg"
    Environment = var.environment
  })
}

resource "aws_vpc_endpoint" "gateway" {
  for_each = var.enable_vpc_endpoints ? var.gateway_endpoint_services : []

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.${each.value}"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = values(aws_route_table.private_route_table)[*].id

  tags = merge(var.tags, {
    Name        = "${var.name}-${each.value}-gateway-endpoint"
    Environment = var.environment
  })
}

resource "aws_vpc_endpoint" "interface" {
  for_each = var.enable_vpc_endpoints ? var.interface_endpoint_services : []

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private_subnet)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name        = "${var.name}-${replace(each.value, ".", "-")}-interface-endpoint"
    Environment = var.environment
  })
}

# ---------------- OPTIONAL PUBLIC NACL ----------------

resource "aws_network_acl" "public_nacl" {

  count = var.create_public_nacl ? 1 : 0

  vpc_id = aws_vpc.main.id

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }

  tags = merge(var.tags, {
    Name        = "${var.name}-public-nacl"
    Environment = var.environment
  })
}

# ---------------- NACL ASSOCIATION ----------------

resource "aws_network_acl_association" "public_nacl_assoc" {

  for_each = var.create_public_nacl ? aws_subnet.public_subnet : {}

  subnet_id      = each.value.id
  network_acl_id = aws_network_acl.public_nacl[0].id
}
