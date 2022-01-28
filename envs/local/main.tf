provider "aws" {
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    s3_force_path_style         = true
    skip_requesting_account_id  = true
    access_key                  = "mock_access_key"
    secret_key                  = "mock_secret_key"
    region                      = var.region
    endpoints {
        dynamodb          = "http://localhost:4566"
        lambda            = "http://localhost:4566"
        s3                = "http://localhost:4566"
        apigateway        = "http://localhost:4566"
        iam               = "http://localhost:4566"
        cloudwatch        = "http://localhost:4566"
        cloudwatchlogs    = "http://localhost:4566"
        kms               = "http://localhost:4566"
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
