data "aws_s3_bucket" "artifacts" {
  bucket = "kernel-builder-artifacts-${var.aws_default_region}-${data.aws_caller_identity.current.account_id}"
}
