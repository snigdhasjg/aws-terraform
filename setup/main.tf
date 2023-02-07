resource "aws_s3_bucket" "terraform_backend" {
  bucket = "terraform-backend-joe-sandbox"
}

resource "aws_s3_bucket_public_access_block" "terraform_bucket_block_all_public_access" {
  bucket = aws_s3_bucket.terraform_backend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_bucket_sse" {
  bucket = aws_s3_bucket.terraform_backend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_iam_openid_connect_provider" "github_actions_oidc" {
  url = "https://token.actions.githubusercontent.com"
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
  client_id_list = [
    "sts.amazonaws.com"
  ]
}

resource "aws_iam_role" "github_actions_role" {
  path               = "/system/pipeline/"
  name               = "github-actions"
  description        = "Role given github action to assume and perform resource creation"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

resource "aws_iam_policy" "github_actions_deny_policy" {
  path        = "/system/pipeline/"
  name        = "github-actions-deny"
  description = "Policy to deny github action to delete its own resource"
  policy      = data.aws_iam_policy_document.github_actions_deny.json
}

resource "aws_iam_role_policy_attachment" "github_actions_deny_policy_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_deny_policy.arn
}

resource "aws_iam_policy" "github_actions_create_policy" {
  path        = "/system/pipeline/"
  name        = "github-actions-allow"
  description = "Policy to allow github action to create any resource"
  policy      = data.aws_iam_policy_document.github_actions_create.json
}

resource "aws_iam_role_policy_attachment" "github_actions_create_policy_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_create_policy.arn
}
