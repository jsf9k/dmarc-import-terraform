# IAM assume role policy document for the role we're creating
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

# The role we're creating
resource "aws_iam_role" "lambda" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# IAM policy document that that allows some S3 permissions on our
# temporary dmarc-import bucket.  This will be applied to the role we
# are creating.
data "aws_iam_policy_document" "s3_lambda" {
  statement {
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.temporary.arn}/*",
    ]
  }
}

# The S3 policy for our role
resource "aws_iam_role_policy" "s3_lambda" {
  policy = data.aws_iam_policy_document.s3_lambda.json
  role   = aws_iam_role.lambda.id
}

# IAM policy document that allows HEADing, POSTing, and PUTting to
# Elasticsearch.  This will be applied to the role we are creating.
data "aws_iam_policy_document" "es_lambda" {
  statement {
    actions = [
      "es:ESHttpHead",
      "es:ESHttpPost",
      "es:ESHttpPut",
    ]
    effect = "Allow"
    resources = [
      aws_elasticsearch_domain.es.arn,
      "${aws_elasticsearch_domain.es.arn}/*",
    ]
  }
}

# The Elasticsearch policy for our role
resource "aws_iam_role_policy" "es_policy" {
  policy = data.aws_iam_policy_document.es_lambda.json
  role   = aws_iam_role.lambda.id
}

# IAM policy document that that allows some SQS permissions on our
# dmarc-import queue.  This will be applied to the role we are
# creating.
data "aws_iam_policy_document" "sqs_lambda" {
  statement {
    actions = [
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
    ]
    effect = "Allow"
    resources = [
      aws_sqs_queue.dmarc_reports.arn,
    ]
  }
}

# The SQS policy for our role
resource "aws_iam_role_policy" "sqs_policy" {
  policy = data.aws_iam_policy_document.sqs_lambda.json
  role   = aws_iam_role.lambda.id
}

# IAM policy document that that allows some Cloudwatch permissions for
# our Lambda function.  This will allow the Lambda function to
# generate log output in Cloudwatch.  This will be applied to the role
# we are creating.
data "aws_iam_policy_document" "cloudwatch_lambda" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect = "Allow"
    resources = [
      aws_cloudwatch_log_group.logs.arn,
      "${aws_cloudwatch_log_group.logs.arn}:*",
    ]
  }
}

# The CloudWatch policy for our role
resource "aws_iam_role_policy" "cloudwatch_policy" {
  policy = data.aws_iam_policy_document.cloudwatch_lambda.json
  role   = aws_iam_role.lambda.id
}

# IAM policy document that that allows the Lambda function to invoke
# itself.  This will be applied to the role we are creating.
data "aws_iam_policy_document" "lambda_lambda" {
  statement {
    actions = [
      "lambda:InvokeFunction",
    ]
    effect = "Allow"
    resources = [
      aws_lambda_function.lambda.arn,
    ]
  }
}

# The Lambda policy for our role
resource "aws_iam_role_policy" "lambda_lambda" {
  policy = data.aws_iam_policy_document.lambda_lambda.json
  role   = aws_iam_role.lambda.id
}
