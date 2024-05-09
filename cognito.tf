# Cognito resources used by the Elasticsearch domain

# Cognito users
resource "aws_cognito_user" "dmarc" {
  for_each = { for k, v in var.cognito_usernames : k => v }

  attributes = {
    email = each.value["email"]
  }
  user_pool_id = aws_cognito_user_pool.dmarc.id
  username     = each.key
}

# The Cognito user pool
resource "aws_cognito_user_pool" "dmarc" {
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  auto_verified_attributes = [
    "email",
  ]

  mfa_configuration = "ON"
  name              = var.cognito_user_pool_name
  software_token_mfa_configuration {
    enabled = true
  }
  user_attribute_update_settings {
    attributes_require_verification_before_update = [
      "email",
    ]
  }
}

# The managed Cognito user pool client for the Elasticsearch endpoint. This
# resource is used to manage the Cognito user pool client that is automatically
# created by Elasticsearch (OpenSearch) when Cognito authentication is enabled.
# Thanks to this comment for pointing me in the right direction:
# https://github.com/hashicorp/terraform-provider-aws/issues/5557#issuecomment-1015731466
resource "aws_cognito_managed_user_pool_client" "dmarc" {
  name_prefix  = "AmazonOpenSearchService-${var.cognito_user_pool_name}"
  user_pool_id = aws_cognito_user_pool.dmarc.id

  # Since our Cognito user pool client is automatically created by Elasticsearch
  # (OpenSearch), we add a manual dependency here to ensure that the
  # Elasticsearch (OpenSearch) domain (and the user pool client) is created
  # before we create this aws_cognito_managed_user_pool_client resource.
  depends_on = [
    aws_elasticsearch_domain.es,
  ]
}

# The Cognito user pool domain
resource "aws_cognito_user_pool_domain" "dmarc" {
  domain       = var.cognito_user_pool_domain
  user_pool_id = aws_cognito_user_pool.dmarc.id
}

# The Cognito identity pool
resource "aws_cognito_identity_pool" "dmarc" {
  allow_unauthenticated_identities = false
  identity_pool_name               = var.cognito_identity_pool_name

  # We don't need to specify the cognito_identity_providers here since the
  # provider is automatically configured by AWS.  This is why we must include
  # the lifecycle block below to ignore changes to cognito_identity_providers.
  #
  # https://docs.aws.amazon.com/opensearch-service/latest/developerguide/cognito-auth.html
  # states: "You don't need to add external identity providers to the identity
  # pool. When you configure OpenSearch Service to use Amazon Cognito
  # authentication, it configures the identity pool to use the user pool that
  # you just created."
  lifecycle {
    ignore_changes = [cognito_identity_providers]
  }
}

# The Cognito identity pool role and related policies
data "aws_iam_policy_document" "cognito_authenticated" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      values   = [aws_cognito_identity_pool.dmarc.id]
      variable = "cognito-identity.amazonaws.com:aud"
    }
    condition {
      test     = "ForAnyValue:StringLike"
      values   = ["authenticated"]
      variable = "cognito-identity.amazonaws.com:amr"
    }
    effect = "Allow"
    principals {
      identifiers = ["cognito-identity.amazonaws.com"]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "cognito_authenticated" {
  assume_role_policy = data.aws_iam_policy_document.cognito_authenticated.json
  name               = var.cognito_authenticated_role_name
}

data "aws_iam_policy_document" "cognito_authenticated_role_policy" {
  statement {
    actions = [
      "cognito-identity:GetCredentialsForIdentity",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cognito_authenticated" {
  name   = "${var.cognito_authenticated_role_name}_policy"
  policy = data.aws_iam_policy_document.cognito_authenticated_role_policy.json
  role   = aws_iam_role.cognito_authenticated.id
}

# Attach the Cognito authenticated role to the Cognito identity pool
resource "aws_cognito_identity_pool_roles_attachment" "dmarc" {
  identity_pool_id = aws_cognito_identity_pool.dmarc.id

  role_mapping {
    ambiguous_role_resolution = "AuthenticatedRole"
    identity_provider         = "cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.dmarc.id}:${aws_cognito_managed_user_pool_client.dmarc.id}"
    type                      = "Rules"

    mapping_rule {
      claim      = "isAdmin"
      match_type = "Equals"
      role_arn   = aws_iam_role.cognito_authenticated.arn
      value      = "yes"
    }
  }

  roles = {
    "authenticated" = aws_iam_role.cognito_authenticated.arn
  }
}

# Trust policy for the IAM role that gives Amazon OpenSearch Service permissions
# to configure the Amazon Cognito user and identity pools and use them for
# OpenSearch Dashboards/Kibana authentication
data "aws_iam_policy_document" "opensearch_cognito_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      identifiers = ["es.amazonaws.com"]
      type        = "Service"
    }
  }
}

# IAM role that gives Amazon OpenSearch Service permissions to configure the
# Amazon Cognito user and identity pools and use them for OpenSearch
# Dashboards/Kibana authentication
resource "aws_iam_role" "opensearch_cognito" {
  assume_role_policy = data.aws_iam_policy_document.opensearch_cognito_trust.json
  name               = var.opensearch_service_role_for_auth_name
}

# IAM policy attachment that gives Amazon OpenSearch Service permissions to
# configure the Amazon Cognito user and identity pools and use them for
# OpenSearch Dashboards/Kibana authentication
resource "aws_iam_role_policy_attachment" "opensearch_cognito" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonOpenSearchServiceCognitoAccess"
  role       = aws_iam_role.opensearch_cognito.name
}
