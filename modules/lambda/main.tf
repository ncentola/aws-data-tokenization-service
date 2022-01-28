data "archive_file" "lambda_tokenizer" {
  type = "zip"

  source_dir  = "${path.module}/tokenizer"
  output_path = "${path.module}/tokenizer.zip"
}

resource "aws_s3_bucket" "tokenizer" {
  bucket  = "2w-tokenizer-lambda-${var.environment}"
  acl     = "private"
}

resource "aws_s3_bucket_object" "lambda_tokenizer" {
  bucket = aws_s3_bucket.tokenizer.id

  key    = "tokenizer.zip"
  source = data.archive_file.lambda_tokenizer.output_path

  etag = filemd5(data.archive_file.lambda_tokenizer.output_path)
}

resource "aws_lambda_function" "tokenizer" {
  function_name = "tokenizer"

  s3_bucket = aws_s3_bucket.tokenizer.id
  s3_key    = aws_s3_bucket_object.lambda_tokenizer.key

  runtime = "python3.7"
  handler = "tokenizer.handler"

  source_code_hash = data.archive_file.lambda_tokenizer.output_base64sha256

  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      REGION            = var.region
      DYNAMODB_ENDPOINT = var.dynamodb_endpoint
      KMS_ENDPOINT      = var.kms_endpoint
      KMS_KEY_ID        = var.kms_key_arn
    }
  }
}

resource "aws_cloudwatch_log_group" "tokenizer" {
  name = "/aws/lambda/${aws_lambda_function.tokenizer.function_name}"

  retention_in_days = 30
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "execution_policy" {

  statement {
    actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "kms:*"
    ]
    resources = [
      var.kms_key_arn
    ]
  }

  statement {
    actions = [
        "dynamodb:BatchGet*",
        "dynamodb:DescribeStream",
        "dynamodb:DescribeTable",
        "dynamodb:Get*",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:BatchWrite*",
        "dynamodb:CreateTable",
        "dynamodb:Delete*",
        "dynamodb:Update*",
        "dynamodb:PutItem"
    ]
    resources = [
      var.dynamodb_tokens_table_arn
    ]
  }
}

resource "aws_iam_policy" "execution_policy" {
  name   = "lambda-tokenizer-execution-policy"
  policy = data.aws_iam_policy_document.execution_policy.json
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.execution_policy.arn
}
