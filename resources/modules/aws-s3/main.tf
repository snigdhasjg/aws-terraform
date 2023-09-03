resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "bucket_block_all_public_access" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "s3_custom_kms" {
  description             = "S3 TWer KMS key"
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "s3_kms_alias" {
  name          = "alias/${var.bucket_name}-key"
  target_key_id = aws_kms_key.s3_custom_kms.key_id
}

resource "aws_kms_key_policy" "s3_kms_cross_account" {
  key_id = aws_kms_key.s3_custom_kms.id
  policy = data.aws_iam_policy_document.allow_kms_access_from_another_account.json
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_sse" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_alias.s3_kms_alias.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy_cross_account" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.allow_s3_access_from_another_account.json
}

resource "aws_s3_object" "data" {
  depends_on = [
    aws_s3_bucket_server_side_encryption_configuration.bucket_sse
  ]

  for_each = fileset("${path.module}/data/", "**")

  bucket      = aws_s3_bucket.this.id
  key         = each.key
  source      = "${path.module}/data/${each.key}"
  source_hash = filemd5("${path.module}/data/${each.key}")
}
