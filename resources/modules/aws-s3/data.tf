data "aws_caller_identity" "this" {}

data "aws_iam_policy_document" "allow_s3_access_from_another_account" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [
        var.cross_account_principal
      ]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = [
        var.cross_account_principal
      ]
    }

    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/macabrEquinox/*",
      "${aws_s3_bucket.this.arn}/generated/*",
    ]
  }
}

data "aws_iam_policy_document" "allow_kms_access_from_another_account" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [
        data.aws_caller_identity.this.account_id
      ]
    }

    actions = ["kms:*"]
    resources = ["*"]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = [
        var.cross_account_principal
      ]
    }

    actions = ["kms:Decrypt"]
    resources = ["*"]
  }
}