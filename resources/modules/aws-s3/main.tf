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

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_sse" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
    }
  }
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
