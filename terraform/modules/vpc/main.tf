# 1. Create a VPC (Virtual Private Cloud)
resource "aws_vpc" "main_vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# 2. Create 1 Public subnet and 2 Private Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs) # Create one public subnet
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = "${var.aws_region}${element(["a", "b"], count.index)}" # Cycles through 'a'
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}" # my-webapp-public-subnet-1
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = "${var.aws_region}${element(["a", "b"], count.index)}"
  map_public_ip_on_launch = false # Private subnets DO NOT need public IPs

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}

# 3. Create an Internet Gateway (for public internet access). 1 is enough for one or more public subnets.
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# 3b. Create a NAT Gateway in a Public Subnet
# You typically put one NAT Gateway per AZ where you have private subnets,
# or for smaller setups, one in a single public subnet.
# For simplicity, we'll place it in the first public subnet (index 0).
resource "aws_eip" "nat_gateway_eip" {
  domain = "vpc" # Required for Elastic IPs in a VPC

  tags = {
    Name = "${var.project_name}-nat-gateway-eip"
  }
}

resource "aws_nat_gateway" "main_nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public[0].id # Place NAT GW in one of the public subnets

  tags = {
    Name = "${var.project_name}-nat-gateway"
  }
}

# 4. Create a Route Table for public and private subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  # Route all internet-bound traffic (0.0.0.0/0) through the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  # Route all internet-bound traffic (0.0.0.0/0) through the NAT Gateway
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main_nat_gateway.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# 5. Associate public subnets with the public route table and private subnets with the private route table
resource "aws_route_table_association" "public" { # Use a generic name, as this will also be a list
  count          = length(aws_subnet.public) # Create one association for each public subnet
  subnet_id      = aws_subnet.public[count.index].id # Reference the subnet by its index
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private) # Create one association for each private subnet
  subnet_id      = aws_subnet.private[count.index].id # Reference the private subnet by its index
  route_table_id = aws_route_table.private_rt.id
}