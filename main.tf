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
  sanitized_user_pool_name = lower(join("-", regexall("[0-9A-Za-z_-]+", var.name)))
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

  allowed_domains_enabled = trimspace(var.allowed_domains) != ""

  # Parse permissions from YAML
  permissions_map = length(var.permissions) > 0 ? yamldecode(var.permissions) : {}

  # Services and their corresponding policies
  services = {
    s3 = {
      read  = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
      write = ["arn:aws:iam::aws:policy/AmazonS3FullAccess"]
    }
  }

  # Process permissions to get list of policy ARNs
  service_policies = length(var.permissions) > 0 ? flatten([
    for service, access_level in local.permissions_map :
    lookup(local.services, service, null) != null ?
    lookup(lookup(local.services, service, {}), access_level, []) : []
  ]) : []

  # Check if permissions are provided
  permissions_enabled = length(var.permissions) > 0 && trimspace(var.permissions) != ""
}

# Package allowed domains Lambda (only when domains are provided)
data "archive_file" "allowed_domains_lambda" {
  count      = local.allowed_domains_enabled ? 1 : 0
  type       = "zip"
  source_dir = "${path.module}/lambda/allowed_domains"
  output_path = "${path.module}/.terraform/allowed-domains.zip"
}

resource "aws_iam_role" "allowed_domains_lambda" {
  count = local.allowed_domains_enabled ? 1 : 0

  name = substr("${local.sanitized_user_pool_name}-allowed-domains-${random_id.suffix.hex}", 0, 64)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "allowed_domains_lambda_logs" {
  count = local.allowed_domains_enabled ? 1 : 0

  name = substr("${local.sanitized_user_pool_name}-allowed-domains-logs-${random_id.suffix.hex}", 0, 128)
  role = aws_iam_role.allowed_domains_lambda[count.index].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "allowed_domains" {
  count = local.allowed_domains_enabled ? 1 : 0

  function_name = substr("${local.sanitized_user_pool_name}-allowed-domains-${random_id.suffix.hex}", 0, 64)
  filename         = data.archive_file.allowed_domains_lambda[count.index].output_path
  source_code_hash = data.archive_file.allowed_domains_lambda[count.index].output_base64sha256
  role             = aws_iam_role.allowed_domains_lambda[count.index].arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 5

  environment {
    variables = {
      ALLOWED_DOMAINS = var.allowed_domains
    }
  }
}

resource "aws_lambda_permission" "allow_cognito" {
  count = local.allowed_domains_enabled ? 1 : 0

  statement_id  = "AllowExecutionFromCognitoPreSignup"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.allowed_domains[count.index].function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.this.arn
}

# Create Cognito User Pool
resource "aws_cognito_user_pool" "this" {
  name = local.user_pool_name

  # Email verification configuration
  auto_verified_attributes = ["email"]

  # Username configuration
  username_configuration {
    case_sensitive = var.case_sensitive
  }

  # Self-registration configuration
  admin_create_user_config {
    allow_admin_create_user_only = !var.self_registration
  }

  dynamic "lambda_config" {
    for_each = local.allowed_domains_enabled ? [aws_lambda_function.allowed_domains[0].arn] : []
    content {
      pre_sign_up = lambda_config.value
    }
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

  schema {
    name                     = "serviceProviderId"
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

  lifecycle {
    ignore_changes = [schema]
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

# Create IAM role for Cognito group (only if permissions are provided)
resource "aws_iam_role" "cognito_group_role" {
  count = local.permissions_enabled ? 1 : 0

  name = substr("${local.sanitized_user_pool_name}-cognito-group-role-${random_id.suffix.hex}", 0, 64)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.this.id}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.this.id}:aud" = aws_cognito_user_pool_client.this.id
        }
        # Require user to be a member of the Cognito group to assume this role
        # The JWT claim is "cognito:groups", so the condition key includes that
        "ForAnyValue:StringEquals" = {
          "cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.this.id}:cognito:groups" = "${local.sanitized_user_pool_name}-group"
        }
      }
    }]
  })
}

# Attach AWS managed policies to the Cognito group role
resource "aws_iam_role_policy_attachment" "cognito_group_policies" {
  for_each = local.permissions_enabled ? { for arn in local.service_policies : replace(basename(arn), ":", "_") => arn } : {}

  role       = aws_iam_role.cognito_group_role[0].name
  policy_arn = each.value
}

# Create Cognito User Pool Group with IAM role (only if permissions are provided)
resource "aws_cognito_user_group" "this" {
  count = local.permissions_enabled ? 1 : 0

  name         = "${local.sanitized_user_pool_name}-group"
  user_pool_id = aws_cognito_user_pool.this.id
  role_arn     = aws_iam_role.cognito_group_role[0].arn
  description  = "Cognito group with IAM role for permissions"
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