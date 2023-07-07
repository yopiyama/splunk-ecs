resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "splunk-net"
  }
}

# resource "aws_flow_log" "vpc-flow-log" {
#   log_destination      = aws_s3_bucket.log-bucket.arn
#   log_destination_type = "s3"
#   traffic_type         = "ALL"
#   vpc_id               = aws_vpc.main.id
# }

# Subnet
resource "aws_subnet" "subnet-public-1a" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1a"

  cidr_block = "172.16.1.0/24"

  tags = {
    Name = "splunk-net-public-1a"
  }
}

resource "aws_subnet" "subnet-public-1c" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1c"

  cidr_block = "172.16.2.0/24"

  tags = {
    Name = "splunk-net-public-1c"
  }
}

# Internet Gateway
# Global to Public subnet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "splunk-net"
  }
}


# Route Table
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "splunk-net"
  }
}

# Route
resource "aws_route" "route" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public-rtb.id
  gateway_id             = aws_internet_gateway.igw.id
}

# Association
resource "aws_route_table_association" "associate-public-1a" {
  subnet_id      = aws_subnet.subnet-public-1a.id
  route_table_id = aws_route_table.public-rtb.id
}

resource "aws_route_table_association" "associate-public-1c" {
  subnet_id      = aws_subnet.subnet-public-1c.id
  route_table_id = aws_route_table.public-rtb.id
}

# Security Group
resource "aws_security_group" "splunk-sg" {
  name   = "splunk-sg"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "splunk-sg-ingress-search" {
  security_group_id = aws_security_group.splunk-sg.id

  type              = "ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks = ["${var.home_ip}", "${var.vpc_cidr}"]
}

resource "aws_security_group_rule" "splunk-sg-ingress-transfer" {
  security_group_id = aws_security_group.splunk-sg.id

  type              = "ingress"
  from_port         = 9997
  to_port           = 9997
  protocol          = "tcp"
  cidr_blocks = ["${var.home_ip}", "${var.vpc_cidr}"]
}

resource "aws_security_group" "efs-sg" {
  name   = "efs-sg"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "efs-sg-ingress" {
  security_group_id = aws_security_group.efs-sg.id

  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks = ["${var.vpc_cidr}"]
}
