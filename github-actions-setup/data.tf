data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "github_actions_deny" {
  statement {
    sid    = "DenyAllIAMResourceRelatedToGithubAction"
    effect = "Deny"
    actions = [
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
    ]
    resources = [
      aws_iam_openid_connect_provider.github_actions_oidc.arn,
      "${aws_iam_role.github_actions_role.arn}*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/system/pipeline/github-actions*"
    ]
  }

  statement {
    sid    = "DenyAllS3ResourceRelatedToGithubAction"
    effect = "Deny"
    actions = [
      "s3:PutBucketAcl",
      "s3:PutBucketPolicy",
      "s3:CreateBucket",
      "s3:DeleteBucketPolicy",
      "s3:DeleteBucket",
      "s3:PutBucketVersioning"
    ]
    resources = [
      aws_s3_bucket.terraform_backend.arn
    ]
  }
}

data "aws_iam_policy_document" "github_actions_create" {
  statement {
    sid    = "AllowEverythingOnTerraformBackendBucket"
    effect = "Allow"

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.terraform_backend.arn,
      "${aws_s3_bucket.terraform_backend.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeAvailabilityZones"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github_actions_oidc.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:snigdhasjg/aws-terraform:environment:sandbox"
      ]
    }
  }
}