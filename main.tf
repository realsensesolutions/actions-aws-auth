# Get current AWS region
data "aws_region" "current" {}

# Generate random suffix for unique resource naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Validate Google provider configuration
locals {
  validate_google_config = var.enable_google_identity_provider && (var.google_client_id == "" || var.google_client_secret == "") ? tobool("Google identity provider is enabled but client_id or client_secret is missing") : true
}

# Discover image files in assets directories
locals {
  user_pool_name = var.name
  # Parse comma-separated URLs into lists
  callback_urls = split(",", var.callback_urls)
  logout_urls   = split(",", var.logout_urls)
  
  # Create branding settings using the example as base and modify form location
  base_branding_settings = jsondecode(file("${path.module}/config/branding-settings-example.json"))
  
  # Modify the form location based on login_position if managed login branding is enabled
  branding_settings_json = var.enable_managed_login_branding ? jsonencode(merge(
    local.base_branding_settings,
    {
      categories = merge(
        local.base_branding_settings.categories,
        {
          form = merge(
            local.base_branding_settings.categories.form,
            {
              location = merge(
                local.base_branding_settings.categories.form.location,
                {
                  horizontal = var.login_position
                }
              )
            }
          )
        }
      )
    }
  )) : null
  
  # Define asset directory mappings
  asset_directories = {
    "background" = "PAGE_BACKGROUND"
    "favicon"    = "FAVICON_ICO"
    "logo"       = "FORM_LOGO"
  }
  
  # Supported image extensions by directory
  supported_extensions = {
    "background" = ["png", "jpg", "jpeg", "svg"]
    "favicon"    = ["ico", "png"]
    "logo"       = ["png", "jpg", "jpeg", "svg"]
  }
  
  # Base path for assets - use workspace root
  assets_base_path = var.assets_base_path != "" ? var.assets_base_path : path.cwd
  
  # Scan for image files in each asset directory
  discovered_assets = flatten([
    for dir_name, category in local.asset_directories : [
      for ext in local.supported_extensions[dir_name] : [
        for file_path in try(fileset("${local.assets_base_path}/assets/${dir_name}", "*.${ext}"), []) : {
          category   = category
          extension  = upper(ext == "jpg" ? "jpeg" : ext)
          bytes      = filebase64("${local.assets_base_path}/assets/${dir_name}/${file_path}")
          color_mode = "LIGHT"
          file_path  = "${dir_name}/${file_path}"
        }
      ]
    ]
  ])
  
  # Convert to the format expected by the managed login branding resource
  branding_assets = var.enable_managed_login_branding ? local.discovered_assets : []
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

# Create Google Identity Provider (only if enabled)
resource "aws_cognito_identity_provider" "google" {
  count = var.enable_google_identity_provider ? 1 : 0

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

  # Supported identity providers - include Google if enabled
  supported_identity_providers = var.enable_google_identity_provider ? ["COGNITO", "Google"] : ["COGNITO"]

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
  client_id    = var.client_id
  
  # Apply branding settings with custom form location
  settings = local.branding_settings_json != null ? local.branding_settings_json : "{}"
  
  # Add automatically discovered branding assets
  assets = local.branding_assets

  # Ensure domain is created first to enable managed login
  depends_on = [aws_cognito_user_pool_domain.this]
}

# Note: Managed Login Branding is only available in CloudFormation, not Terraform
# For now, we'll use the default Cognito UI styling