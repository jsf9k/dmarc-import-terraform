# Make a new rule set for handling the DMARC aggregate report emails
# that arrive
resource "aws_ses_receipt_rule_set" "rules" {
  rule_set_name = var.rule_set_name
}

# Make a rule for handling the DMARC aggregate report emails that
# arrive
resource "aws_ses_receipt_rule" "rule" {
  enabled       = true
  name          = "receive-dmarc-emails"
  recipients    = var.emails
  rule_set_name = aws_ses_receipt_rule_set.rules.rule_set_name
  scan_enabled  = true

  # Save to the permanent S3 bucket
  s3_action {
    bucket_name = aws_s3_bucket.permanent.id
    position    = 1
  }

  # Save to the temporary S3 bucket
  s3_action {
    bucket_name = aws_s3_bucket.temporary.id
    position    = 2
  }
}

# Make this rule set the active one
resource "aws_ses_active_receipt_rule_set" "active" {
  rule_set_name = aws_ses_receipt_rule_set.rules.rule_set_name
}
