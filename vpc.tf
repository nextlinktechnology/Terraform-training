resource "aws_vpc" "vpc" {
  cidr_block           = "10.128.0.0/16"
  enable_dns_hostnames = "true"
  tags = {
    Name = "Circle vpc"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.vpc.id
  availability_zone = "eu-west-3a"
  cidr_block = "10.128.1.0/24"
  tags = {
    Name = "Circle subnet1"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Circle gateway"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.r.id
}

resource "aws_route" "ipv4-outbound" {
  route_table_id         = aws_route_table.r.id
  gateway_id             = aws_internet_gateway.gw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Circle route"
  }
}
