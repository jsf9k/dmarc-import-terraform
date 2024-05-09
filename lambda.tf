# The AWS Lambda function that processes DMARC aggregate report emails
resource "aws_lambda_function" "lambda" {
  description      = "Lambda function for processing DMARC aggregate report emails"
  filename         = var.lambda_function_zip_file
  function_name    = var.lambda_function_name
  handler          = "lambda_handler.handler"
  memory_size      = 128
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.6"
  source_code_hash = filebase64sha256(var.lambda_function_zip_file)
  timeout          = 300

  environment {
    variables = {
      elasticsearch_index  = var.elasticsearch_index
      elasticsearch_region = var.aws_region
      elasticsearch_url    = "https://${aws_elasticsearch_domain.es.endpoint}"
      queue_url            = aws_sqs_queue.dmarc_reports.id
    }
  }
}

# Allows CloudWatch to invoke this Lambda function
resource "aws_lambda_permission" "allow_cloudwatch" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  statement_id  = "AllowExecutionFromCloudWatch"
}

# AWS CloudWatch rule to run the Lambda function
resource "aws_cloudwatch_event_rule" "lambda" {
  description         = "Run the Lambda function for importing DMARC aggregate report emails"
  is_enabled          = true
  name                = "ImportDmarcAggregateReports"
  schedule_expression = "rate(5 minutes)"
}

# Target for the CloudWatch rule
resource "aws_cloudwatch_event_target" "lambda" {
  arn  = aws_lambda_function.lambda.arn
  rule = aws_cloudwatch_event_rule.lambda.name
}

# The Cloudwatch log group for the Lambda function
resource "aws_cloudwatch_log_group" "logs" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 30
}
