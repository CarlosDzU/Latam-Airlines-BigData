# Bucket del data lake: bronze, silver y gold viven aquí como prefijos.

resource "random_id" "sufijo" {
  byte_length = 4
}

resource "aws_s3_bucket" "lake" {
  bucket        = "${var.proyecto}-lake-${random_id.sufijo.hex}"
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_public_access_block" "lake" {
  bucket                  = aws_s3_bucket.lake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "lake" {
  bucket = aws_s3_bucket.lake.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lake" {
  bucket = aws_s3_bucket.lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Rechaza cualquier acceso que no sea por HTTPS.
data "aws_iam_policy_document" "solo_https" {
  statement {
    sid     = "DenegarSinTLS"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      aws_s3_bucket.lake.arn,
      "${aws_s3_bucket.lake.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "lake" {
  bucket = aws_s3_bucket.lake.id
  policy = data.aws_iam_policy_document.solo_https.json

  depends_on = [aws_s3_bucket_public_access_block.lake]
}

# Limpieza automática de lo que no hace falta guardar.
resource "aws_s3_bucket_lifecycle_configuration" "lake" {
  bucket = aws_s3_bucket.lake.id

  rule {
    id     = "resultados-athena"
    status = "Enabled"
    filter {
      prefix = "athena-results/"
    }
    expiration {
      days = 7
    }
  }

  rule {
    id     = "replicas-escalabilidad"
    status = "Enabled"
    filter {
      prefix = "scale-test/"
    }
    expiration {
      days = 7
    }
  }

  rule {
    id     = "subidas-incompletas"
    status = "Enabled"
    filter {}
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}
