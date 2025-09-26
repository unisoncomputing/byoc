# The table that stores all of the objects persisted by the Unison Cloud `State` ability.
resource "aws_dynamodb_table" "unison_cloud_byoc_state" {
  name           = local.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"

  # productionization: set this to true
  deletion_protection_enabled = false

  hash_key       = "K"
  range_key      = "NS"

  # key
  attribute {
    name = "K"
    type = "B"
  }

  # namespace
  attribute {
    name = "NS"
    type = "S"
  }

  tags = {
    Name        = "cloud-byoc"
    Environment = "byoc"
  }
}

resource "aws_iam_policy" "byoc_container_dynamo_policy" {
  description = "byoc containers need to connect to dynamodb"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
