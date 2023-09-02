data "aws_iam_policy_document" "allow_access_from_another_account" {
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
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/model/*",
      "${aws_s3_bucket.this.arn}/generated/*",
    ]
  }
}