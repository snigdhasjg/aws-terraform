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
  path        = "/system/pipeline/"
  name        = "github-actions"
  description = "Role given github action to assume and perform resource creation"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions_oidc.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:snigdhasjg/aws-terraform:*"
          }
        }
      },
    ]
  })
}

resource "aws_iam_policy" "github_actions_deny_policy" {
  path        = "/system/pipeline/"
  name        = "github-actions-deny"
  description = "Policy to deny github action to delete its own resource"

  policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyAllIAMResourceRelatedToGithubAction",
      "Effect": "Deny",
      "Action": [
        "iam:UpdateAssumeRolePolicy",
        "iam:UntagRole",
        "iam:PutRolePermissionsBoundary",
        "iam:TagRole",
        "iam:UpdateOpenIDConnectProviderThumbprint",
        "iam:DeletePolicy",
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePermissionsBoundary",
        "iam:PassRole",
        "iam:DetachRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:CreatePolicyVersion",
        "iam:DeleteOpenIDConnectProvider",
        "iam:RemoveClientIDFromOpenIDConnectProvider",
        "iam:DeleteRole",
        "iam:UpdateRoleDescription",
        "iam:TagPolicy",
        "iam:CreateOpenIDConnectProvider",
        "iam:CreatePolicy",
        "iam:CreateServiceLinkedRole",
        "iam:UntagPolicy",
        "iam:UpdateRole",
        "iam:DeleteServiceLinkedRole",
        "iam:UntagOpenIDConnectProvider",
        "iam:AddClientIDToOpenIDConnectProvider",
        "iam:TagOpenIDConnectProvider",
        "iam:DeletePolicyVersion",
        "iam:SetDefaultPolicyVersion"
      ],
      "Resource": [
        "${aws_iam_openid_connect_provider.github_actions_oidc.arn}",
        "${aws_iam_role.github_actions_role.arn}",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/system/pipeline/github-actions*"
      ]
    },
    {
      "Sid": "DenyAllS3ResourceRelatedToGithubAction",
      "Effect": "Deny",
      "Action": [
          "s3:PutBucketAcl",
          "s3:PutBucketPolicy",
          "s3:CreateBucket",
          "s3:DeleteBucketPolicy",
          "s3:DeleteBucket",
          "s3:PutBucketVersioning"
      ],
      "Resource": "${aws_s3_bucket.terraform_backend.arn}"
    }
  ]
}
EOT
}

resource "aws_iam_role_policy_attachment" "github_actions_deny_policy_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_deny_policy.arn
}

resource "aws_iam_policy" "github_actions_create_policy" {
  path        = "/system/pipeline/"
  name        = "github-actions-allow"
  description = "Policy to allow github action to create any resource"

  policy = data.aws_iam_policy_document.github_actions_create.json
}

resource "aws_iam_role_policy_attachment" "github_actions_create_policy_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_create_policy.arn
}
