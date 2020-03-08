data "archive_file" "lambda-app" {
  type = "zip"
  source_file = "${path.module}/files/instance-launcher/main.py"
  output_path = "${path.module}/files/instance-launcher.zip"
}

resource "aws_iam_role" "lambda" {
  name        = "LambdaKernelBuilder"
  description = "Role to enable Lambda Kernel Builder to use AWS resources"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_access_to_kernel_builder_resources" {
  name = "KernelBuilderLambdaResourcesAccess"
  description = "Enables access to resources required by Kernel Builder from Lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:CreateTags"
      ],
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action":"iam:PassRole",
      "Resource":"${aws_iam_role.main.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_access_to_role" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_access_to_kernel_builder_resources.arn
}

resource "aws_lambda_function" "auto-builder" {
  function_name = "Auto-Kernel-Builder"

  filename = data.archive_file.lambda-app.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda-app.output_path)
  handler = "main.handler"
  role = aws_iam_role.lambda.arn

  // Add ssh & git to the lambda runtime
  // see: https://github.com/lambci/git-lambda-layer
  layers = ["arn:aws:lambda:us-east-1:553035198032:layer:git-lambda2:4"]

  runtime = "python3.8"
  timeout = 30

  environment {
    variables = {
      LAUNCH_TEMPLATE_NAME = aws_launch_template.main.name,
    }
  }
}
