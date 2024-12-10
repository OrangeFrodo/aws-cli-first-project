# VPC 
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "VPC_Intenrship_Jakub"
  }
}

# Public subnet
resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.main_vpc.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet-${count.index}_Internship_Jakub"
  }
}

# Subnets (Each EC2 instance gets its own private subnet)
resource "aws_subnet" "private_subnet" {
  count                   = 2 # Create 2 private subnets
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.main_vpc.cidr_block, 8, count.index + 3)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "PrivateSubnet-${count.index}_Internship_Jakub"
  }
}

# Create Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example_igw.id
  }

  tags = {
    Name = "PublicRouteTable_Internship_Jakub"
  }
}

# Create Route Table for Private Subnet
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example_nat.id
  }

  tags = {
    Name = "PrivateRouteTable_Internship_Jakub"
  }
}

# Associate Subnets with Route Table
resource "aws_route_table_association" "private_route_table_association" {
  count          = length(aws_subnet.private_subnet)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# Public Route Table Association
resource "aws_route_table_association" "public_subnet_association" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

## PUBLIC not doing in NAT Gateway
# # Create NAT Gateway for Private Subnet
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# Create NAT Gateway
resource "aws_nat_gateway" "example_nat" {
  allocation_id = aws_eip.nat_eip.id             # Ensure this points to the Elastic IP
  subnet_id     = aws_subnet.public_subnet[0].id # NAT in the first public subnet

  tags = {
    Name = "NATGateway_Internship_Jakub"
  }

  depends_on = [aws_eip.nat_eip]
}

# Create Internet Gateway
resource "aws_internet_gateway" "example_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "InterentGateway_Internship_Jakub"
  }
}

data "aws_availability_zones" "available" {}
