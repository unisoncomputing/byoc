# DynamoDB table for storing Unison Cloud state
resource "aws_dynamodb_table" "unison_cloud_byoc_state" {
  name           = local.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "${var.cluster_name}-state"
    Environment = "byoc"
    Project     = "unison-cloud"
  }
}
