# ------------------------------------------------------------------------------
# REQUIRED PARAMETERS
#
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------

variable "elasticsearch_domain_name" {
  description = "The domain name of the Elasticsearch instance."
  type        = string
}

variable "elasticsearch_index" {
  description = "The Elasticsearch index to which to write DMARC aggregate report data."
  type        = string
}

variable "elasticsearch_type" {
  description = "The Elasticsearch type corresponding to a DMARC aggregate report."
  type        = string
}

variable "emails" {
  description = "A list of the email addresses at which DMARC aggregate reports are being received."
  type        = list(string)
}

variable "lambda_function_name" {
  description = "The name to use for the Lambda function."
  type        = string
}

variable "lambda_function_zip_file" {
  description = "The location of the zip file for the Lambda function."
  type        = string
}

variable "permanent_bucket_name" {
  description = "The name of the S3 bucket where the DMARC aggregate report emails are stored permanently."
  type        = string
}

variable "queue_name" {
  description = "The name of the SQS queue where events will be sent as DMARC aggregate reports are received."
  type        = string
}

variable "rule_set_name" {
  description = "The name of the SES rule set that processes DMARC aggregate reports."
  type        = string
}

variable "temporary_bucket_name" {
  description = "The name of the S3 bucket where the DMARC aggregate report emails are stored temporarily (until processed)."
  type        = string
}

# ------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
#
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------

variable "aws_region" {
  default     = "us-east-1"
  description = "The AWS region to deploy into (e.g. us-east-1)."
  type        = string
}

variable "cognito_authenticated_role_name" {
  default     = "dmarc-import-authenticated"
  description = "The name of the IAM role that grants authenticated access to the Elasticsearch database."
  type        = string
}

variable "cognito_identity_pool_name" {
  default     = "dmarc-import"
  description = "The name of the Cognito identity pool to use for access to the Elasticsearch database."
  type        = string
}

variable "cognito_user_pool_client_name" {
  default     = "dmarc-import"
  description = "The name of the Cognito user pool client to use for access to the Elasticsearch database."
  type        = string
}

variable "cognito_user_pool_domain" {
  default     = "dmarc-import"
  description = "The domain to use for the Cognito endpoint. For custom domains, this is the fully-qualified domain name, such as auth.example.com. For Amazon Cognito prefix domains, this is the prefix alone, such as auth."
  type        = string
}

variable "cognito_user_pool_name" {
  default     = "dmarc-import"
  description = "The name of the Cognito user pool to use for access to the Elasticsearch database."
  type        = string
}

variable "cognito_usernames" {
  default     = {}
  description = "A map whose keys are the usernames of each Cognito user and whose values are a map containing supported user attributes.  The only currently-supported attribute is \"email\" (string).  Example: { \"firstname1.lastname1\" = { \"email\" = \"firstname1.lastname1@foo.gov\" }, \"firstname2.lastname2\" = { \"email\" = \"firstname2.lastname2@foo.gov\" } }"
  type        = map(object({ email = string }))
}

variable "opensearch_service_role_for_auth_name" {
  default     = "opensearch-service-cognito-access"
  description = "The name of the IAM role that gives Amazon OpenSearch Service permissions to configure the Amazon Cognito user and identity pools and use them for OpenSearch Dashboards/Kibana authentication."
  type        = string
}
