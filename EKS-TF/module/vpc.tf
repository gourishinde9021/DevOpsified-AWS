locals {
  cluster-name = var.cluster-name
}

resource "aws_vpc" "vpc" {
  cidr_block = var.cidr-block
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = var.vpc_name
    Env = var.env
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.igw-name
    env = var.env
    "kubernetes.io/cluster/${local.cluster-name}" = "owned"
  }
  depends_on = [ aws_vpc.vpc ]
}

resource "aws_subnet" "public-subnet" {
  count = var.pub-subnet-count
  vpc_id = aws_vpc.vpc.id
  cidr_block = element(var.pub-cidr-block, count.index)
  availability_zone = element(var.pub-availability-zone, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.public-sub-name}-${count.index + 1}"
    Env = var.env
    "kubernetes.io/cluster/${local.cluster-name}" = "owned"
    "kubernetes.io/role/elb" = 1
  }
  depends_on = [ aws_vpc.vpc,
   ]
}

resource "aws_subnet" "private-subnet" {
  count = var.pri-sub-name
  vpc_id = aws_vpc.vpc.id
  cidr_block = element(var.pri-cidr-block, count.index)
  availability_zone = element(var.pri-availability-zone, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.pri-sub-name}-${count.index + 1}"
    Env = var.env
    "kubernetes.io/cluster/${local.cluster-name}" = "owned"
    "kubernetes.io/role/elb" = 1
  }
  depends_on = [ aws_vpc.vpc,
   ]
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = var.public-rt-name
    Env = var.env
  }
  depends_on = [ aws_vpc.vpc ]
}

resource "aws_route_table_association" "public-rt-association" {
  count = 3
  route_table_id = aws_route_table.public-rt.id
  subnet_id = aws_subnet.public-subnet[count.index].id

  depends_on = [ aws_vpc.vpc,
  aws_subnet.public-subnet
  ]
}

resource "aws_eip" "ngw_eip" {
  domain = "vpc"

  tags = {
    Name = var.eip-name
  }
  depends_on = [ aws_vpc.vpc ]
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw_eip.id
  subnet_id = aws_subnet.public-subnet[0].id

  tags = {
    Name = var.ngw-name.id
  }
  depends_on = [ aws_vpc.vpc,
  aws_eip.ngw_eip ]
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = var.private-rt-name
    Env = var.env
  }
  depends_on = [ aws_vpc.vpc ]
}

resource "aws_route_table_association" "private-rt-association" {
  count = 3
  route_table_id = aws_route_table.private-rt.id
  subnet_id = aws_subnet.private-subnet[count.index].id

  depends_on = [ aws_vpc.vpc,
  aws_subnet.private-subnet
  ]
}

resource "aws_security_group" "eks-cluster-sg" {
  name = var.eks-sg
  description = "Allow 443 from Jump server only"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = var.eks-sg
  }
}