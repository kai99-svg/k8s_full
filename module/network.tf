########################################
# NETWORKING - VPC, Subnets, IGW, Routing
########################################
# Variable for subnet CIDR prefixes

# Create a VPC
resource "aws_vpc" "first_vpc" {
  enable_dns_support   = true #enable private DNS on a VPC endpoint.
  enable_dns_hostnames = true #enable private DNS on a VPC endpoint.
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Web_vpc"
  }
}

# Create Subnets
resource "aws_subnet" "public" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.first_vpc.id
  cidr_block        = var.public_subnets[count.index].cidr_block
  availability_zone = var.public_subnets[count.index].availability_zone
  tags = {
    Name = "public_subnet_${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.first_vpc.id
  cidr_block        = var.private_subnets[count.index].cidr_block
  availability_zone = var.private_subnets[count.index].availability_zone
  tags = {
    Name = "private_subnet_${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.first_vpc.id
  tags = {
    Name = "first_igw"
  }
}

resource "aws_nat_gateway" "nat" {
  subnet_id = aws_subnet.public[0].id
  allocation_id = aws_eip.nat_eip.id
}

# Route Table
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.first_vpc.id
  route {
  cidr_block = "10.0.0.0/16"
  gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "prod_route"
  }
}

resource "aws_route_table" "nat_route_table" {
  vpc_id = aws_vpc.first_vpc.id
  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "nat_route"
  }
}

# Route Table Associations

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.nat_route_table.id
}

