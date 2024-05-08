# This is the SQS queue where events will be sent as DMARC aggregate
# reports are received
resource "aws_sqs_queue" "dmarc_reports" {
  message_retention_seconds = 1209600
  name                      = var.queue_name
  receive_wait_time_seconds = 20
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.dead_letter.arn}\",\"maxReceiveCount\":4}"
}

# This is the dead-letter queue for the previous SQS queue
resource "aws_sqs_queue" "dead_letter" {
  message_retention_seconds = 1209600
  name                      = "${var.queue_name}_dead_letter"
}

# IAM policy document that that allows S3 to write to the queue
data "aws_iam_policy_document" "s3_sqs" {
  statement {
    actions = [
      "sqs:SendMessage",
    ]
    effect = "Allow"
    principals {
      identifiers = ["s3.amazonaws.com"]
      type        = "Service"
    }
    resources = [
      aws_sqs_queue.dmarc_reports.arn,
    ]
  }
}

# This is the policy for our SQS queue
resource "aws_sqs_queue_policy" "dmarc_reports" {
  policy    = data.aws_iam_policy_document.s3_sqs.json
  queue_url = aws_sqs_queue.dmarc_reports.id
}
