# The CloudWatch log group where application logs will be written
resource "aws_cloudwatch_log_group" "es_logs" {
  name              = "/aws/aes/domains/${var.elasticsearch_domain_name}/application-logs"
  retention_in_days = 30
}

# IAM policy document that that allows ES to write to CloudWatch logs
data "aws_iam_policy_document" "es_cloudwatch_doc" {
  statement {
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
    ]
    effect = "Allow"
    principals {
      identifiers = ["es.amazonaws.com"]
      type        = "Service"
    }
    resources = [
      aws_cloudwatch_log_group.es_logs.arn,
      "${aws_cloudwatch_log_group.es_logs.arn}:*",
    ]
  }
}

resource "aws_cloudwatch_log_resource_policy" "es_cloudwatch_policy" {
  policy_document = data.aws_iam_policy_document.es_cloudwatch_doc.json
  policy_name     = "dmarc-import-es-cloudwatch-policy"
}

# Policy document that allows authenticated Cognito users access to the
# Elasticsearch domain
data "aws_iam_policy_document" "es_cognito_auth" {
  statement {
    actions = [
      "es:*",
    ]
    effect = "Allow"
    principals {
      identifiers = [
        aws_iam_role.cognito_authenticated.arn,
      ]
      type = "AWS"
    }
    resources = [
      "arn:aws:es:${var.aws_region}:*:domain/${var.elasticsearch_domain_name}/*",
    ]
  }
}

# The Elasticsearch domain
resource "aws_elasticsearch_domain" "es" {
  access_policies       = data.aws_iam_policy_document.es_cognito_auth.json
  domain_name           = var.elasticsearch_domain_name
  elasticsearch_version = "OpenSearch_1.3"

  cluster_config {
    instance_type  = "m6g.large.elasticsearch"
    instance_count = 3
    zone_awareness_config {
      availability_zone_count = 3
    }
    zone_awareness_enabled = true
  }

  cognito_options {
    enabled          = true
    identity_pool_id = aws_cognito_identity_pool.dmarc.id
    role_arn         = aws_iam_role.opensearch_cognito.arn
    user_pool_id     = aws_cognito_user_pool.dmarc.id
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 100
    volume_type = "gp2"
  }

  encrypt_at_rest {
    enabled = true
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.es_logs.arn
    log_type                 = "ES_APPLICATION_LOGS"
  }
}
