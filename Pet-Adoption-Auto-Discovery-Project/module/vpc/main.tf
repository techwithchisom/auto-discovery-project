locals {
  name = "petclinic"
}
# Creating VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${local.name}-vpc"
  }
}

# Creating public subnet
resource "aws_subnet" "publicsub" {
  vpc_id            = aws_vpc.vpc.id
  count             = 3
  cidr_block        = element(var.public-subnet, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "${local.name}-public-subnet"
  }
}

resource "aws_subnet" "privatesub" {
  vpc_id            = aws_vpc.vpc.id
  count             = 3
  cidr_block        = element(var.private-subnet, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "${local.name}-private-subnet"
  }
}

# creating internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.name}-igw"
  }
}

# create route table
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${local.name}-public-rt"
  }
}

resource "aws_route_table_association" "pubrt-ass" {
  count          = 3
  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.publicsub[count.index].id
}

resource "aws_eip" "eip" {
  domain = "vpc"
  tags = {
    Name = "${local.name}-eip"
  }
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.publicsub[0].id
  tags = {
    Name = "${local.name}-nat-gw"
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gw.id
  }
  tags = {
    Name = "${local.name}-private-rt"
  }
}
resource "aws_route_table_association" "prvrt-ass" {
  count          = 3
  route_table_id = aws_route_table.private-rt.id
  subnet_id      = aws_subnet.privatesub[count.index].id
}