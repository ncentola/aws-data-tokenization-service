provider "aws" {
  region  = "us-east-1"
  profile = "REPLACE_ME"     # TODO - put your profile here
}

terraform {
  backend "s3" {
    bucket  = "REPLACE_ME"
    key     = "REPLACE_ME"
    region  = "REPLACE_ME"
    profile = "REPLACE_ME"
  }
}

module "dynamodb" {
    source = "../../modules/dynamodb"

    environment               = var.environment
}

module "kms" {
  source = "../../modules/kms"

  key_description = "Tokenizer encryption key"
}

module "lambda" {
  source = "../../modules/lambda"

  environment               = var.environment
  region                    = var.region
  dynamodb_endpoint         = var.dynamodb_endpoint
  dynamodb_tokens_table_arn = module.dynamodb.tokens_table_arn

  kms_endpoint              = var.kms_endpoint
  kms_key_arn               = module.kms.arn
}

module "api_gateway" {
    source = "../../modules/api_gateway"

    environment               = var.environment
    lambda_invoke_arn         = module.lambda.invoke_arn
    lambda_function_name      = module.lambda.function_name
}
