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

  # This instance size is enough for a VPN
  instance_type = "t3a.nano"

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

  # user_data = <<-SCRIPT
  #   #!/usr/bin/env bash
  #   # Bootstrap the server using the bundled playbook
  #   # Current version: ${data.aws_s3_bucket_object.release_id.body}
  #   #
  #   aws s3 cp s3://${var.artifacts_s3_bucket}/vpn/playbook.run /root/playbook.run
  #   chmod +x /root/playbook.run
  #   yum install -y python2-pip
  #   /root/playbook.run
  #   rm /root/playbook.run
  # SCRIPT

  # Spot attributes
  wait_for_fulfillment = true
  spot_type = "one-time"
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "EC2 ${aws_spot_instance_request.main.tags["Name"]} - CPU usage above 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "80"

  dimensions = {
    InstanceId = aws_spot_instance_request.main.id
  }

  alarm_actions = [data.aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "memory_alarm" {
  alarm_name          = "EC2 ${aws_spot_instance_request.main.tags["Name"]} - Memory usage above 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "80"

  dimensions = {
    InstanceId = aws_spot_instance_request.main.id
  }

  alarm_actions = [data.aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "disk_alarm" {
  alarm_name          = "EC2 ${aws_spot_instance_request.main.tags["Name"]} - Disk usage above 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "80"

  dimensions = {
    InstanceId = aws_spot_instance_request.main.id
    device     = "nvme0n1p1"
    fstype     = "xfs"
    path       = "/"
  }

  alarm_actions = [data.aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_credits" {
  alarm_name          = "EC2 ${aws_spot_instance_request.main.tags["Name"]} - CPU credits too low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "60"
  metric_name         = "CPUCreditBalance"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"

  dimensions = {
    InstanceId = aws_spot_instance_request.main.id
  }

  alarm_actions = [data.aws_sns_topic.alarms.arn]
}
