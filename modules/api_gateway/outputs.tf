output "api_id"   { value = aws_api_gateway_rest_api.tokenizer.id           }
output "base_url" { value = aws_api_gateway_deployment.tokenizer.invoke_url }
