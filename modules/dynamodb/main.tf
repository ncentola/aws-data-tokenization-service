resource "aws_dynamodb_table" "tokens" {
  name           = "tokens"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "hash"
  # range_key      = "GameTitle"

  attribute {
    name = "hash"
    type = "S"
  }

  attribute {
    name = "token"
    type = "S"
  }

  # -- Bug in terraform causes issues when setting TTL.
  # -- Will default to infinite TTL anyway so commenting this out

  # ttl {
  #   attribute_name = "TimeToExist"
  #   enabled        = false
  # }

  global_secondary_index {
    name               = "TokenIndex"
    hash_key           = "token"
    # range_key          = "TopScore"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "ALL"
    # non_key_attributes = ["UserId"]
  }


  tags = {
    Name        = "tokens"
    Environment = var.environment
  }
}
