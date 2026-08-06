locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project            = var.project_name
    Environment        = var.environment
    ManagedBy          = "Terraform"
    DataClassification = "synthetic-only"
  }
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.this.id
  availability_zone = var.availability_zones[count.index]
  cidr_block        = var.public_subnet_cidrs[count.index]

  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name             = "${local.name_prefix}-public-${count.index + 1}"
    Tier             = "public"
    AvailabilityZone = var.availability_zones[count.index]
  })
}

resource "aws_subnet" "application" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.this.id
  availability_zone = var.availability_zones[count.index]
  cidr_block        = var.application_subnet_cidrs[count.index]

  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name             = "${local.name_prefix}-application-${count.index + 1}"
    Tier             = "private-application"
    AvailabilityZone = var.availability_zones[count.index]
  })
}

resource "aws_subnet" "database" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.this.id
  availability_zone = var.availability_zones[count.index]
  cidr_block        = var.database_subnet_cidrs[count.index]

  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name             = "${local.name_prefix}-database-${count.index + 1}"
    Tier             = "isolated-database"
    AvailabilityZone = var.availability_zones[count.index]
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-routes"
    Tier = "public"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "application" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name             = "${local.name_prefix}-application-routes-${count.index + 1}"
    Tier             = "private-application"
    AvailabilityZone = var.availability_zones[count.index]
  })
}

resource "aws_route_table_association" "application" {
  count = length(aws_subnet.application)

  subnet_id      = aws_subnet.application[count.index].id
  route_table_id = aws_route_table.application[count.index].id
}

resource "aws_route_table" "database" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name             = "${local.name_prefix}-database-routes-${count.index + 1}"
    Tier             = "isolated-database"
    AvailabilityZone = var.availability_zones[count.index]
  })
}

resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[count.index].id
}
