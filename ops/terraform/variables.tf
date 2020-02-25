variable "main_public_ssh_key" {
  type        = string
  description = "The public SSH key used for using with AWS CodeCommit and EC2"
}

variable "repo_s3_bucket" {
  type        = string
  description = "The S3 bucket where the DEB repo is located"
}

variable "repo_s3_apt_path" {
  type        = string
  description = "The path on S3 where the repository should be stored"
}

variable "aws_default_region" {
  type        = string
  description = "The default AWS region"
}
