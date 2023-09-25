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
    sid = "AllowManagingIAMRoleAndPolicy"
    effect = "Allow"

    actions = [
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:UpdateAssumeRolePolicy",
      "iam:UntagRole",
      "iam:TagRole",
      "iam:UpdateRoleDescription",
      "iam:DeletePolicy",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:AttachRolePolicy",
      "iam:PutRolePolicy",
      "iam:TagPolicy",
      "iam:CreatePolicy",
      "iam:DetachRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:UntagPolicy",
      "iam:CreatePolicyVersion",
      "iam:UntagInstanceProfile",
      "iam:DeletePolicyVersion",
      "iam:TagInstanceProfile",
      "iam:SetDefaultPolicyVersion",
      "iam:PassRole",
    ]

    resources = ["*"]
  }

  statement {
    sid = "AllowManagingEC2Instance"
    effect = "Allow"

    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:DeleteTags",
      "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
      "ec2:StartInstances",
      "ec2:CreateSecurityGroup",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RebootInstances",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
      "ec2:DetachNetworkInterface",
      "ec2:TerminateInstances",
      "ec2:CreateTags",
      "ec2:ResetNetworkInterfaceAttribute",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:DeleteNetworkInterface",
      "ec2:RunInstances",
      "ec2:ModifySecurityGroupRules",
      "ec2:StopInstances",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteSecurityGroup",
      "ec2:AttachNetworkInterface",
      "ec2:ImportKeyPair",
      "ec2:CreateKeyPair",
      "ec2:DeleteKeyPair",
      "ec2:ModifyInstanceAttribute"
    ]

    resources = ["*"]
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