output "user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.this.id
}

output "user_pool_client_secret" {
  description = "Secret of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.this.client_secret
  sensitive   = true
}

output "user_pool_domain" {
  description = "Domain of the Cognito User Pool"
  value       = aws_cognito_user_pool_domain.this.domain
}

output "login_url" {
  description = "Login URL for the Cognito Hosted UI"
  value       = "https://${aws_cognito_user_pool_domain.this.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.this.id}&response_type=code&scope=email+openid+profile&redirect_uri=${split(",", var.callback_urls)[0]}"
}

output "discovered_branding_assets" {
  description = "Information about automatically discovered branding assets"
  value = var.enable_managed_login_branding ? {
    asset_count = length(local.branding_assets)
    assets = [
      for asset in local.branding_assets : {
        category  = asset.category
        extension = asset.extension
        file_path = asset.file_path
        size_kb   = length(asset.bytes) / 1024
      }
    ]
  } : null
}

output "cognito_domain" {
  description = "Cognito provided domain URL"
  value       = "https://${aws_cognito_user_pool_domain.this.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}

output "managed_login_branding_enabled" {
  description = "Whether managed login branding is enabled"
  value       = var.enable_managed_login_branding
}

output "managed_login_version" {
  description = "Managed login version used by the domain"
  value       = aws_cognito_user_pool_domain.this.managed_login_version
}

output "managed_login_branding_id" {
  description = "ID of the managed login branding resource (if enabled)"
  value       = var.enable_managed_login_branding ? awscc_cognito_managed_login_branding.this[0].id : null
}

output "hosted_ui_url" {
  description = "Hosted UI URL for sign-in (uses managed login if enabled)"
  value       = "https://${aws_cognito_user_pool_domain.this.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.this.id}&response_type=code&scope=email+openid+profile&redirect_uri=${urlencode(local.callback_urls[0])}"
}

output "google_identity_provider_enabled" {
  description = "Whether Google identity provider is enabled"
  value       = var.enable_google_identity_provider
}

output "google_identity_provider_name" {
  description = "Name of the Google identity provider (if enabled)"
  value       = var.enable_google_identity_provider ? aws_cognito_identity_provider.google[0].provider_name : null
}

output "supported_identity_providers" {
  description = "List of supported identity providers (comma-separated)"
  value       = join(",", aws_cognito_user_pool_client.this.supported_identity_providers)
}

output "branding_trigger_hash" {
  description = "Hash of the current branding trigger state (helps track when branding should be recreated)"
  value       = var.enable_managed_login_branding ? terraform_data.branding_trigger[0].input : null
}