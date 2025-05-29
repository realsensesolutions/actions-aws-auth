# Example usage of managed login branding functionality

module "cognito_with_branding" {
  source = "./"

  # Basic Cognito configuration
  name          = "my-company-pool"
  callback_urls = "https://myapp.com/callback,https://myapp.com/auth"
  logout_urls   = "https://myapp.com/logout,https://myapp.com/"

  # Enable managed login branding
  enable_managed_login_branding = true
  branding_settings_file        = "branding-settings-example.json"

  # Branding assets (JSON string with base64 encoded files from your repository)
  branding_assets = jsonencode([
    {
      category   = "LOGO"
      extension  = "png"
      bytes      = filebase64("${path.module}/assets/logo-light.png")
      color_mode = "LIGHT"
    },
    {
      category   = "LOGO"
      extension  = "png"
      bytes      = filebase64("${path.module}/assets/logo-dark.png")
      color_mode = "DARK"
    },
    {
      category   = "FAVICON"
      extension  = "ico"
      bytes      = filebase64("${path.module}/assets/favicon.ico")
      color_mode = "LIGHT"
    },
    {
      category   = "EMAIL_GRAPHIC"
      extension  = "png"
      bytes      = filebase64("${path.module}/assets/email-header.png")
      color_mode = "LIGHT"
    }
  ])
}

# Example with minimal configuration (uses default Cognito UI)
module "cognito_default" {
  source = "./"

  name                          = "default-pool"
  enable_managed_login_branding = false  # This is the default
}

# Example with branding enabled but no custom assets
module "cognito_settings_only" {
  source = "./"

  name                          = "settings-only-pool"
  enable_managed_login_branding = true
  branding_settings_file        = "branding-settings-example.json"
  # branding_assets is empty by default (empty JSON array), so only JSON settings will be applied
}

# Outputs from the branding-enabled module
output "branded_pool_info" {
  value = {
    user_pool_id                  = module.cognito_with_branding.user_pool_id
    hosted_ui_url                = module.cognito_with_branding.hosted_ui_url
    managed_login_branding_enabled = module.cognito_with_branding.managed_login_branding_enabled
    managed_login_version         = module.cognito_with_branding.managed_login_version
  }
} 