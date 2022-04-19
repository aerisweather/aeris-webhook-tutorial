locals {
  output_path  = "${path.root}/outputs"
  service_name = "aerisweather-webhook-tutorial"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "random_password" "x_webhook_tutorial_key" {
  length = 16

  upper   = true
  lower   = true
  number  = true
  special = false
}

resource "local_file" "x_webhook_tutorial_key" {
  filename = "${local.output_path}/x-webhook-tutorial-key.txt"
  content  = "${random_password.x_webhook_tutorial_key.result}\n"

  directory_permission = "0700"
  file_permission      = "0600"
}

resource "local_file" "webhook_endpoint_url" {
  filename = "${local.output_path}/webhook-url.txt"
  content  = "${local.webhook_url}\n"

  directory_permission = "0700"
  file_permission      = "0600"
}
