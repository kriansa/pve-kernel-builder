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

resource "aws_s3_bucket_object" "cloudwatch_config" {
  bucket = data.aws_s3_bucket.artifacts.id
  key = "cloudwatch-agent-config.json"
  content = templatefile("${path.module}/files/cloudwatch-agent-config.json", {
    aws_default_region = var.aws_default_region,
  })
}

resource "aws_s3_bucket_object" "env_file" {
  bucket = data.aws_s3_bucket.artifacts.id
  key = ".env"
  content = templatefile("${path.module}/files/.env", {
    aws_default_region = var.aws_default_region,
    artifacts_s3_bucket = data.aws_s3_bucket.artifacts.id,
    repo_s3_bucket = var.repo_s3_bucket,
    repo_s3_apt_path = var.repo_s3_apt_path,
  })
}

data "template_cloudinit_config" "ec2_cloudinit" {
  gzip = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/files/ec2_cloud_config.yml", {
      artifacts_s3_bucket = data.aws_s3_bucket.artifacts.id,
      cloudwatch_config_path = aws_s3_bucket_object.cloudwatch_config.key,
      env_file_path = aws_s3_bucket_object.env_file.key,
    })
  }
}

resource "aws_spot_instance_request" "main" {
  ami      = data.aws_ami.amazon_linux.id
  key_name = aws_key_pair.main.key_name

  # An instance powerful enough to compile it quickly but not so expensive
  instance_type = "m5.2xlarge"

  # The role used for this EC2
  iam_instance_profile = aws_iam_instance_profile.main.name

  # Networking
  subnet_id = aws_subnet.main.id
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.ec2_instance.id,
    aws_security_group.allow_ssh_from_vpn.id,
  ]

  # cloud-init data to configure the instance
  user_data = data.template_cloudinit_config.ec2_cloudinit.rendered

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
