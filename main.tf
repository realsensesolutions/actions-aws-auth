# Get current AWS region
data "aws_region" "current" {}

# Generate random suffix for unique resource naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Read branding settings from JSON file if provided
locals {
  user_pool_name = var.name
  # Parse comma-separated URLs into lists
  callback_urls = split(",", var.callback_urls)
  logout_urls   = split(",", var.logout_urls)
  
  # Read branding settings from JSON file as string if provided and file exists
  # The AWS CloudFormation resource expects a JSON string, not a parsed object
  branding_settings = var.enable_managed_login_branding && var.branding_settings_file != "" ? try(file(var.branding_settings_file), null) : null
  
  # Parse branding assets from JSON string or file (file takes priority if both provided)
  branding_assets = var.enable_managed_login_branding ? (
    var.branding_assets_file != "" ? try(jsondecode(file(var.branding_assets_file)), []) : jsondecode(var.branding_assets)
  ) : []
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

# Create User Pool Domain with managed login support
resource "aws_cognito_user_pool_domain" "this" {
  domain       = "${lower(local.user_pool_name)}-${random_id.suffix.hex}"
  user_pool_id = aws_cognito_user_pool.this.id
  
  # Enable managed login version if branding is enabled
  managed_login_version = var.enable_managed_login_branding ? 2 : null
}

# Create Managed Login Branding (only if enabled)
resource "awscc_cognito_managed_login_branding" "this" {
  count = var.enable_managed_login_branding ? 1 : 0

  user_pool_id = aws_cognito_user_pool.this.id
  client_id    = aws_cognito_user_pool_client.this.id
  
  # Apply branding settings from JSON file as string (only if settings file is provided)
  settings = local.branding_settings != null ? local.branding_settings : "{}"
  
  # Add branding assets as direct argument, not dynamic block
  assets = local.branding_assets

  # Ensure domain is created first to enable managed login
  depends_on = [aws_cognito_user_pool_domain.this]
  
  # Force replacement when client_id changes since it's a create-only property
  lifecycle {
    replace_triggered_by = [
      aws_cognito_user_pool_client.this.id
    ]
  }
}

# Note: Managed Login Branding is only available in CloudFormation, not Terraform
# For now, we'll use the default Cognito UI styling