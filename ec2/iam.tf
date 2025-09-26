# IAM role for Unison Cloud instances
resource "aws_iam_role" "unison" {
  name = "${var.cluster_name}-unison-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-unison-role"
    Environment = "byoc"
    Project     = "unison-cloud"
  }
}

# IAM policy for S3 access
resource "aws_iam_role_policy" "unison_s3" {
  name = "${var.cluster_name}-unison-s3-policy"
  role = aws_iam_role.unison.id

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
}

# IAM policy for CloudWatch logs
resource "aws_iam_role_policy" "unison_cloudwatch" {
  name = "${var.cluster_name}-unison-cloudwatch-policy"
  role = aws_iam_role.unison.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance profile for Unison instances
resource "aws_iam_instance_profile" "unison" {
  name = "${var.cluster_name}-unison-profile"
  role = aws_iam_role.unison.name

  tags = {
    Name        = "${var.cluster_name}-unison-profile"
    Environment = "byoc"
    Project     = "unison-cloud"
  }
}
