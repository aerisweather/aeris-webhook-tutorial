data "aws_iam_policy_document" "webhook_lambda_assume_role" {
  statement {
    sid     = "AllowLambdaAssumeRole"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "webhook" {
  name = local.service_name

  assume_role_policy = data.aws_iam_policy_document.webhook_lambda_assume_role.json
}

data "archive_file" "lambda_archive" {
  type = "zip"

  output_path = "${local.output_path}/lambda-archive.zip"

  source {
    content  = file("${path.root}/../webhook.py")
    filename = "webhook.py"
  }
}

resource "aws_lambda_function" "webhook" {
  function_name = local.service_name
  handler       = "webhook.lambda_handler"
  role          = aws_iam_role.webhook.arn

  filename         = data.archive_file.lambda_archive.output_path
  source_code_hash = data.archive_file.lambda_archive.output_sha
  runtime          = "python3.8"

  memory_size = 128

  environment {
    variables = {
      X_WEBHOOK_TUTORIAL_KEY = random_password.x_webhook_tutorial_key.result
    }
  }
}
