# S3 bucket for Unison Cloud native services
resource "aws_s3_bucket" "unison_cloud_byoc_native_services" {
  bucket_prefix = "unison-cloud-byoc-services"
  force_destroy = true

  tags = {
    Name        = "${var.cluster_name}-services"
    Environment = "byoc"
    Project     = "unison-cloud"
  }
}

resource "aws_s3_bucket_public_access_block" "unison_cloud_byoc_native_services" {
  bucket = aws_s3_bucket.unison_cloud_byoc_native_services.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket for Unison Cloud user blobs
resource "aws_s3_bucket" "unison_cloud_byoc_blobs" {
  bucket_prefix = "unison-cloud-byoc-blobs"
  force_destroy = true

  tags = {
    Name        = "${var.cluster_name}-blobs"
    Environment = "byoc"
    Project     = "unison-cloud"
  }
}

resource "aws_s3_bucket_public_access_block" "unison_cloud_byoc_blobs" {
  bucket = aws_s3_bucket.unison_cloud_byoc_blobs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM policy for EC2 instances to access S3 buckets
resource "aws_iam_policy" "byoc_container_s3_policy" {
  name_prefix = "byoc-container-s3-"
  path        = "/"
  description = "IAM policy for BYOC containers to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.unison_cloud_byoc_native_services.arn,
          "${aws_s3_bucket.unison_cloud_byoc_native_services.arn}/*",
          aws_s3_bucket.unison_cloud_byoc_blobs.arn,
          "${aws_s3_bucket.unison_cloud_byoc_blobs.arn}/*"
        ]
      }
    ]
  })

  tags = {
    Environment = "byoc"
    Project     = "unison-cloud"
  }
}

# IAM policy for EC2 instances to access DynamoDB
resource "aws_iam_policy" "byoc_container_dynamo_policy" {
  name_prefix = "byoc-container-dynamo-"
  path        = "/"
  description = "IAM policy for BYOC containers to access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:ConditionCheckItem",
          "dynamodb:PutItem",
          "dynamodb:DescribeTable",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.unison_cloud_byoc_state.arn
      }
    ]
  })

  tags = {
    Environment = "byoc"
    Project     = "unison-cloud"
  }
}
