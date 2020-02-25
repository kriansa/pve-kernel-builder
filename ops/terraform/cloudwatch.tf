resource "aws_cloudwatch_log_group" "main" {
  name = "Kernel-Builder"
  retention_in_days = 30
}
