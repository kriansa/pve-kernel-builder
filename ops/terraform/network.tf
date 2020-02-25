# Create a VPC for this purpose only
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  # This is required so that EFS volumes can be reached within VPC
  # https://docs.aws.amazon.com/efs/latest/ug/troubleshooting-efs-mounting.html
  enable_dns_hostnames = true

  tags = {
    Name = "Kernel Builder"
  }
}

# Create a subnet on first AZ of this region
resource "aws_subnet" "main" {
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, 1) // 10.0.1.0/24
  availability_zone = data.aws_availability_zones.available.names[0]
  vpc_id            = aws_vpc.main.id

  tags = {
    Name = "[Kernel-Builder] Public-Inbound-AZ1"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "[Kernel-Builder] Default"
  }
}

# Default route table allows all outbound access to internet gateway
resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "[Kernel-Builder] Default"
  }
}

resource "aws_security_group" "ec2_instance" {
  name        = "KernelBuilderEC2Instance"
  description = "Security group to identify traffic from/to Kernel Builder EC2 instance"
  vpc_id      = aws_vpc.main.id

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "allow_ssh_from_vpn" {
  name        = "AllowSSHFromEverywhere"
  description = "Allow inbound SSH traffic everywhere."
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
}
