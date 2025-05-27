# Get current AWS region
data "aws_region" "current" {}

# Generate random suffix for unique resource naming
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  user_pool_name = var.name
  # Parse comma-separated URLs into lists
  callback_urls = split(",", var.callback_urls)
  logout_urls   = split(",", var.logout_urls)
}

# Create Cognito User Pool
resource "aws_cognito_user_pool" "this" {
  name = local.user_pool_name

  # Email verification configuration
  auto_verified_attributes = ["email"]

  # Allow users to sign themselves up
  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  # MFA configuration
  mfa_configuration = "OFF"

  # Email schema configuration
  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true
  }

  # Password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  tags = {
    Name = local.user_pool_name
  }
}

# Create User Pool Client
resource "aws_cognito_user_pool_client" "this" {
  name         = "${local.user_pool_name}-client"
  user_pool_id = aws_cognito_user_pool.this.id

  # Generate client secret
  generate_secret = true

  # OAuth configuration
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile", "aws.cognito.signin.user.admin"]

  # Callback and logout URLs
  callback_urls = local.callback_urls
  logout_urls   = local.logout_urls

  # Supported identity providers
  supported_identity_providers = ["COGNITO"]

  # Token validity
  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

# Note: Managed Login Branding is only available in CloudFormation, not Terraform
# For now, we'll use the default Cognito UI styling