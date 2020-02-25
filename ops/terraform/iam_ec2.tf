resource "aws_iam_role" "main" {
  name        = "EC2KernelBuilder"
  description = "Role to enable EC2 Kernel Builder to use AWS resources"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "enable_access_to_kernel_builder_resources" {
  name = "KernelBuilderResourcesFullAccessResources"
  description = "Enables access to resources required by Kernel Builder"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::${var.repo_s3_bucket}", "arn:aws:s3:::${data.aws_s3_bucket.artifacts.id}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:HeadObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": ["arn:aws:s3:::${var.repo_s3_bucket}/*", "arn:aws:s3:::${data.aws_s3_bucket.artifacts.id}/*"]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "pki_policy_to_role" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.enable_access_to_kernel_builder_resources.arn
}

data "aws_iam_policy" "cw_agent" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "cw_agent_to_role" {
  role       = aws_iam_role.main.name
  policy_arn = data.aws_iam_policy.cw_agent.arn
}

data "aws_iam_policy" "ssm" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ssm_to_role" {
  role       = aws_iam_role.main.name
  policy_arn = data.aws_iam_policy.ssm.arn
}

# Instance Profile is a abstraction to link a Role with an EC2 instance
# Other services such as ECS allows you to pass a Role directly on launch
resource "aws_iam_instance_profile" "main" {
  name = "EC2KernelBuilder"
  role = aws_iam_role.main.name
}
