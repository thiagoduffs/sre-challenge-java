resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket        = "eks-codepipeline-artifacts-${random_string.suffix.result}"
  force_destroy = true
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
