output "base_url" {
  value = "http://localhost:4566/restapis/${module.api_gateway.api_id}/${var.environment}/_user_request_/tokenizer"
}
