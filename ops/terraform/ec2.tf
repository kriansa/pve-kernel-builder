# Get the latest AMI for ECS
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["amazon"]
}

resource "aws_key_pair" "main" {
  key_name   = "kernel-builder-deploy-key"
  public_key = var.main_public_ssh_key
}

data "template_cloudinit_config" "ec2_cloudinit" {
  gzip = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/ec2_cloud_config.yml", {
      aws_default_region = var.aws_default_region,
      artifacts_s3_bucket = var.artifacts_s3_bucket,
      repo_s3_bucket = var.repo_s3_bucket
    })
  }
}

resource "aws_spot_instance_request" "main" {
  ami      = data.aws_ami.amazon_linux.id
  key_name = aws_key_pair.main.key_name

  # An instance powerful enough to compile it quickly
  instance_type = "m5.4xlarge"

  # The role used for this EC2
  iam_instance_profile = aws_iam_instance_profile.main.name

  # Networking
  subnet_id = aws_subnet.main.id
  associate_public_ip_address = true
  vpc_security_group_ids = [
    data.aws_security_group.default.id,
    aws_security_group.allow_ssh_from_vpn.id,
  ]

  # cloud-init data to configure the instance
  user_data = data.template_cloudinit_config.ec2_cloudinit.rendered

  # Enable T3 unlimited CPU credits scheduling
  credit_specification {
    cpu_credits = "unlimited"
  }

  tags = {
    Name = "Kernel Builder"
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = 70
  }

  # Spot attributes
  wait_for_fulfillment = true
  spot_type = "one-time"
}
