resource "aws_api_gateway_rest_api" "webhook_tutorial_api" {
  name        = local.service_name
  description = "API for the AerisWeather webhook tutorial."

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.webhook_tutorial_api.id
  parent_id   = aws_api_gateway_rest_api.webhook_tutorial_api.root_resource_id
  path_part   = "webhook"
}

resource "aws_api_gateway_method" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.webhook_tutorial_api.id
  resource_id = aws_api_gateway_resource.webhook.id
  http_method = "POST"

  # Note: in an actual API Gateway application, you would want to use
  # a separate authorization method. Since we only have one endpoint,
  # there is no need to increase complexity by adding an authorization
  # Lambda.
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.webhook_tutorial_api.id
  resource_id = aws_api_gateway_resource.webhook.id
  http_method = aws_api_gateway_method.webhook.http_method
  type        = "AWS_PROXY"
  uri         = aws_lambda_function.webhook.invoke_arn

  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "webhook" {
  depends_on  = [aws_api_gateway_integration.webhook]
  rest_api_id = aws_api_gateway_rest_api.webhook_tutorial_api.id
}

resource "aws_api_gateway_stage" "webhook" {
  rest_api_id   = aws_api_gateway_rest_api.webhook_tutorial_api.id
  stage_name    = "tutorial"
  deployment_id = aws_api_gateway_deployment.webhook.id
}

resource "aws_api_gateway_method_settings" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.webhook_tutorial_api.id
  stage_name  = aws_api_gateway_stage.webhook.stage_name
  method_path = "${aws_api_gateway_resource.webhook.path_part}/${aws_api_gateway_method.webhook.http_method}"

  settings {
    logging_level          = "INFO"
    throttling_rate_limit  = 100
    throttling_burst_limit = 100
  }
}

locals {
  webhook_url                  = "${aws_api_gateway_stage.webhook.invoke_url}${aws_api_gateway_resource.webhook.path}"
  rest_api_source_arn_resource = "${aws_api_gateway_rest_api.webhook_tutorial_api.id}/*/${aws_api_gateway_method.webhook.http_method}${aws_api_gateway_resource.webhook.path}"
}

resource "aws_lambda_permission" "api_gateway_webhook_lambda_invocation" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webhook.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.rest_api_source_arn_resource}"
}

output "api_gateway_webhook_url" {
  value       = local.webhook_url
  description = "the URL at which the webhook can be triggered"
}
