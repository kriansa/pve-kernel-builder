# Use an existing VPC
data "aws_vpc" "main" {
  id = var.vpc_id
}

# Create a subnet on first AZ of this region
resource "aws_subnet" "main" {
  cidr_block        = cidrsubnet(data.aws_vpc.main.cidr_block, 8, 2) // 10.0.2.0/24
  availability_zone = data.aws_availability_zones.available.names[0]
  vpc_id            = data.aws_vpc.main.id
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-App-AZ1"
  }
}

data "aws_security_group" "default" {
  name = "default"
  vpc_id = data.aws_vpc.main.id
}

resource "aws_security_group" "allow_ssh_from_vpn" {
  name        = "AllowSSHFromVPN"
  description = "Allow inbound SSH traffic from the VPN"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    security_groups = [data.aws_security_group.default.id]
  }
}
