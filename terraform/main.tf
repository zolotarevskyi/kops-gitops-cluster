terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Де Terraform зберігатиме свій власний стейт
  backend "local" {}
}

provider "aws" {
  region = var.aws_region
}

# --------------------------
# 1. S3 Bucket для Kops state
# --------------------------
resource "aws_s3_bucket" "kops_state" {
  bucket = var.kops_state_bucket
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.kops_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --------------------------
# 2. Route53 Hosted Zone
# --------------------------
resource "aws_route53_zone" "kops_zone" {
  name = var.kops_subdomain
}

# --------------------------
# 3. IAM User для Kops
# --------------------------
resource "aws_iam_user" "kops_user" {
  name = "kops-admin-roman"
}

resource "aws_iam_user_policy_attachment" "admin_policy" {
  user       = aws_iam_user.kops_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_access_key" "kops_credentials" {
  user = aws_iam_user.kops_user.name
}

