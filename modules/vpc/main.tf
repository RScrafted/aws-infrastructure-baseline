# -----------------------------------------------------------------------------
# VPC: The main isolation boundary
# -----------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-vpc"
    }
  )
}

# Optional: Adopt default VPC route table to enforce clean tagging and prevent unmanaged routes
resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  tags = merge(
    var.tags,
    { Name = "${var.project_name}-default-rt" }
  )
}

# -----------------------------------------------------------------------------
# SUBNETS: Segmenting the network into Public and Private tiers
# -----------------------------------------------------------------------------

## Public Subnets - Tier for Internet-facing resources (ALB)
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "eu-west-2a"
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-sn-a"
    }
  )
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "eu-west-2b"
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-sn-b"
    }
  )
}

## Private Subnets - Tier for restricted resources (EC2/ASG)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.10.0/24"
  availability_zone = "eu-west-2a"
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-sn-a"
    }
  )
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.20.0/24"
  availability_zone = "eu-west-2b"
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-sn-b"
    }
  )
}

# -----------------------------------------------------------------------------
# GATEWAYS: Handling ingress (IGW) and egress (NAT)
# -----------------------------------------------------------------------------

## Internet Gateway - Allows the VPC to speak to the world
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-igw"
    }
  )
}

## Elastic IP - Static address required for the NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-nat-eip"
    }
  )
}

## NAT Gateway - Allows Private Subnets to reach the internet for updates
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id # Must live in Public to work
  depends_on    = [aws_internet_gateway.igw]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-nat"
    }
  )
}

# -----------------------------------------------------------------------------
# ROUTING: Defining how traffic flows between subnets and gateways
# -----------------------------------------------------------------------------

## Public Route Table - Routes 0.0.0.0/0 to the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-rt"
    }
  )
}

## Private Route Table - Routes 0.0.0.0/0 to the NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-rt"
    }
  )
}

## Associations - Linking Route Tables to specific Subnets
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}