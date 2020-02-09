variable "main_public_ssh_key" {
  type        = string
  description = "The public SSH key used for using with AWS CodeCommit and EC2"
}

variable "repo_s3_bucket" {
  type        = string
  description = "The S3 bucket where the DEB repo is located"
}

variable "artifacts_s3_bucket" {
  type        = string
  description = "The name of the S3 bucket we use to store application artifacts."
}

variable "vpc_id" {
  type        = string
  description = "The ID of the existing VPC"
}

variable "aws_default_region" {
  type        = string
  description = "The default AWS region"
}
