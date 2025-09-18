# Get current AWS region
data "aws_region" "current" {}

# Generate random suffix for unique resource naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Parse providers and validate configuration
locals {
  # Parse identity providers list (normalize case and remove empty values)
  providers_list = [
    for provider in split("\n", replace(var.idp, " ", "\n")) :
    lower(trimspace(provider)) if trimspace(provider) != ""
  ]
  
  # Check which providers are enabled
  enable_google = contains(local.providers_list, "google")
  enable_cognito = contains(local.providers_list, "cognito")
  
}

# Discover image files in assets directories
locals {
  user_pool_name = var.name
  # Parse comma-separated URLs into lists
  callback_urls = split(",", var.callback_urls)
  logout_urls   = split(",", var.logout_urls)
  
  # Generate branding settings using templatefile for clean configuration
  branding_settings_json = var.enable_managed_login_branding ? templatefile("${path.module}/config/branding-settings.json.tftpl", {
    horizontal_position = var.login_position
  }) : null
  
  # Helper function to extract and normalize file extension
  get_file_extension = {
    background = var.background_asset_path != "" ? (
      lower(regex("\\.([^.]+)$", var.background_asset_path)[0]) == "jpg" ? "JPEG" : 
      upper(regex("\\.([^.]+)$", var.background_asset_path)[0])
    ) : ""
    logo = var.logo_asset_path != "" ? (
      lower(regex("\\.([^.]+)$", var.logo_asset_path)[0]) == "jpg" ? "JPEG" : 
      upper(regex("\\.([^.]+)$", var.logo_asset_path)[0])
    ) : ""
    favicon = var.favicon_asset_path != "" ? (
      lower(regex("\\.([^.]+)$", var.favicon_asset_path)[0]) == "jpg" ? "JPEG" : 
      upper(regex("\\.([^.]+)$", var.favicon_asset_path)[0])
    ) : ""
  }
  
  # Create branding assets from direct asset paths
  branding_assets = var.enable_managed_login_branding ? [
    for asset in [
      var.background_asset_path != "" ? {
        category   = "PAGE_BACKGROUND"
        extension  = local.get_file_extension.background
        bytes      = filebase64(var.background_asset_path)
        color_mode = "LIGHT"
      } : null,
      var.logo_asset_path != "" ? {
        category   = "FORM_LOGO"
        extension  = local.get_file_extension.logo
        bytes      = filebase64(var.logo_asset_path)
        color_mode = "LIGHT"
      } : null,
      var.favicon_asset_path != "" ? {
        category   = "FAVICON_ICO"
        extension  = local.get_file_extension.favicon
        bytes      = filebase64(var.favicon_asset_path)
        color_mode = "LIGHT"
      } : null
    ] : asset if asset != null
  ] : []
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

  # Custom attributes schema configuration
  schema {
    name                     = "tenantId"
    attribute_data_type      = "String"
    mutable                  = true
    required                 = false
    developer_only_attribute = false
    
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    name                     = "userRole"
    attribute_data_type      = "String"
    mutable                  = true
    required                 = false
    developer_only_attribute = false
    
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    name                     = "apiKey"
    attribute_data_type      = "String"
    mutable                  = true
    required                 = false
    developer_only_attribute = false
    
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    name                     = "tenantTier"
    attribute_data_type      = "String"
    mutable                  = true
    required                 = false
    developer_only_attribute = false
    
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
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

# Create Google Identity Provider (only if enabled)
resource "aws_cognito_identity_provider" "google" {
  count = local.enable_google ? 1 : 0

  user_pool_id  = aws_cognito_user_pool.this.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    client_id                = var.google_client_id
    client_secret            = var.google_client_secret
    authorize_scopes         = "email openid profile"
    attributes_url           = "https://people.googleapis.com/v1/people/me?personFields="
    attributes_url_add_attributes = "true"
    authorize_url            = "https://accounts.google.com/o/oauth2/v2/auth"
    oidc_issuer              = "https://accounts.google.com"
    token_url                = "https://www.googleapis.com/oauth2/v4/token"
    token_request_method     = "POST"
  }

  attribute_mapping = {
    email      = "email"
    username   = "sub"
    given_name = "given_name"
    family_name = "family_name"
    picture    = "picture"
    name = "name"
  }
}

# Create User Pool Client
resource "aws_cognito_user_pool_client" "this" {
  name         = "${local.user_pool_name}-client"
  user_pool_id = aws_cognito_user_pool.this.id

  # Generate client secret
  generate_secret = true

  # Authentication flows
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_CUSTOM_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]

  # OAuth configuration
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile", "aws.cognito.signin.user.admin"]

  # Callback and logout URLs
  callback_urls = local.callback_urls
  logout_urls   = local.logout_urls

  # Supported identity providers - dynamic based on idp configuration
  supported_identity_providers = local.enable_google && local.enable_cognito ? ["COGNITO", "Google"] : (
    local.enable_google ? ["Google"] : ["COGNITO"]
  )

  # Token validity
  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "days"
    id_token      = "days"
    refresh_token = "days"
  }

  # Ensure Google identity provider is created before client when enabled
  depends_on = [
    aws_cognito_identity_provider.google
  ]
}


# Create User Pool Domain with managed login support
resource "aws_cognito_user_pool_domain" "this" {
  domain                 = "${lower(local.user_pool_name)}-${random_id.suffix.hex}"
  user_pool_id          = aws_cognito_user_pool.this.id
  managed_login_version = var.enable_managed_login_branding ? 2 : null
}

# Create Managed Login Branding (only if enabled)
resource "awscc_cognito_managed_login_branding" "this" {
  count = var.enable_managed_login_branding ? 1 : 0

  user_pool_id = aws_cognito_user_pool.this.id
  client_id    = aws_cognito_user_pool_client.this.id
  
  # Apply branding settings with custom form location
  settings = local.branding_settings_json != null ? local.branding_settings_json : "{}"
  
  # Add branding assets from provided asset paths
  assets = local.branding_assets

  # Ensure domain is created first to enable managed login
  depends_on = [aws_cognito_user_pool_domain.this]
}

# Create admin user (only if admin_email is provided)
resource "aws_cognito_user" "admin" {
  count        = var.admin_email != "" ? 1 : 0
  user_pool_id = aws_cognito_user_pool.this.id
  username     = "admin"
  
  # Let Cognito generate temporary password automatically
  # When temporary_password is omitted, Cognito generates one and sends it via email
  
  attributes = {
    email           = var.admin_email
    email_verified  = true
  }
  
  # Force password change on first login and send via email
  desired_delivery_mediums = ["EMAIL"]
  
  depends_on = [aws_cognito_user_pool.this]
}