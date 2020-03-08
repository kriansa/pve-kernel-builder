resource "aws_cloudwatch_log_group" "main" {
  name = "Kernel-Builder"
  retention_in_days = 30
}

resource "aws_cloudwatch_event_rule" "daily_schedule" {
  name = "KernelCompiler-Run-Lambda-Compile-Checker-Daily"
  description = "Run the Kernel Builder checker Lambda once every day"

  schedule_expression = "rate(1 day)"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto-builder.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.daily_schedule.arn
}

resource "aws_cloudwatch_event_target" "run_lambda_daily" {
  target_id = "KernelCompiler-Run-Lambda-Compile-Checker-Daily"
  rule = aws_cloudwatch_event_rule.daily_schedule.name
  arn = aws_lambda_function.auto-builder.arn
}
