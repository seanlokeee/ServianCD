#Assigned a block of IP addresses using CIDR notation which is used to assign 
#internal IP addresses to deployed services like EC2 instances
resource "aws_vpc" "app_vpc" {
  #CIDR range is notation for number of IPs
  cidr_block = "10.0.0.0/16" #contain 9 ranges of 10.0.0.0/22
  tags = {                   #10.0.0.0/16 stores 65000 ip addresses 
    Name = "${var.name}-${var.env}-vpc"
  }
}

#Different subnet and VPC take ownership of different ranges of IP addresses,
#allowing AWS to automatically allocate IP address in right location
#One 10.0.0.0/22 stores 1000 ip addresses
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.0.0/22" #/22 represent range from 10.0.0.0 to 10.0.3.255
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { #any ip address within range above will fall in public subnet az1
    Name = "${var.name}-${var.env}-public-az1"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.4.0/22" #range represented from 10.0.4.0 to 10.0.7.255
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { #tag is added so that easily can find it in console later
    Name = "${var.name}-${var.env}-public-az2"
  }
}

resource "aws_subnet" "public_az3" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.8.0/22"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-${var.env}-public-az3"
  }
}

resource "aws_subnet" "private_az1" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.16.0/22"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-${var.env}-private-az1"
  }
}

resource "aws_subnet" "private_az2" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.20.0/22"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-${var.env}-private-az2"
  }
}

resource "aws_subnet" "private_az3" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.24.0/22"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-${var.env}-private-az3"
  }
}

resource "aws_subnet" "data_az1" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.32.0/22"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-${var.env}-data-az1"
  }
}

resource "aws_subnet" "data_az2" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.36.0/22"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-${var.env}-data-az2"
  }
}

resource "aws_subnet" "data_az3" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.40.0/22"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-${var.env}-data-az3"
  }
}

#Living outside of subnets, it connects VPC to internet and servers because it 
#allows services within VPC with public IP to access internet 
resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "${var.name}-${var.env}-igw"
  }
}

#Automatically created after VPC is created
#Doesn't have route toandfro internet but route for internal communication VPC
resource "aws_default_route_table" "app_rt" {
  default_route_table_id = aws_vpc.app_vpc.default_route_table_id
  route {
    #Every connection to 0.0.0.0 without a specific rule
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_igw.id
  }
  tags = {
    Name = "${var.name}-${var.env}-route-table"
  }
}
