resource "aws_s3_bucket" "unison_cloud_byoc_native_services" {
  bucket_prefix = "unison-cloud-byoc-services"
  force_destroy = true
}

resource "aws_s3_bucket" "unison_cloud_byoc_blobs" {
  bucket_prefix = "unison-cloud-byoc-blobs"
  force_destroy = true
}

resource "aws_iam_policy" "byoc_container_s3_policy" {
  description = "build servers need to docker push, connect to rds"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:*"
        ],
        "Resource" : "*"
      },
      {
       "Effect": "Allow",
       "Action": [
         "s3:ListBucket",
         "s3:ListBucketVersions",
       ],
       "Resource": [ aws_s3_bucket.unison_cloud_byoc_native_services.arn, 
                     aws_s3_bucket.unison_cloud_byoc_blobs.arn ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:AbortMultipartUpload"
        ],
        "Resource": [ "${aws_s3_bucket.unison_cloud_byoc_native_services.arn}/*", 
                      "${aws_s3_bucket.unison_cloud_byoc_blobs.arn}/*"]
      },
      {
        "Effect": "Allow",
        "Action": [
          "dynamodb:GetItem",
          "dynamodb:ConditionCheckItem",
          "dynamodb:TransactWriteItems",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:Scan"
        ],
        "Resource": [ "${aws_dynamodb_table.unison_cloud_byoc_state.arn}" ]
      }
    ]
  })
}
