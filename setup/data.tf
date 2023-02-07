data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "github_actions_create" {
  statement {
    sid     = "AllowEverythingOnTerraformBackendBucket"
    effect  = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.terraform_backend.arn,
      "${aws_s3_bucket.terraform_backend.arn}/*"
    ]
  }

  statement {
    effect  = "Allow"
    actions = [
      "ec2:DescribeAvailabilityZones"
    ]
    resources = [
      "*"
    ]
  }
}