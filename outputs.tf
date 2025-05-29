output "user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.arn
}

output "client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.this.id
}

output "client_secret" {
  description = "Secret of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.this.client_secret
  sensitive   = true
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