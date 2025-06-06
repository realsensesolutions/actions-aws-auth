variable "name" {
  description = "Name of the Cognito User Pool - will be used as the Name tag"
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "Name cannot be empty"
  }
}

variable "callback_urls" {
  description = "Comma-separated list of callback URLs for OAuth"
  type        = string
  default     = "https://example.com/callback"
}

variable "logout_urls" {
  description = "Comma-separated list of logout URLs for OAuth"
  type        = string
  default     = "https://example.com"
}

variable "enable_managed_login_branding" {
  description = "Enable managed login branding for Cognito UI customization with automatic asset discovery from assets/ directory"
  type        = bool
  default     = false
}

variable "login_position" {
  description = "Login form horizontal position: START, CENTER, or END (only works when enable_managed_login_branding is true)"
  type        = string
  default     = "CENTER"
  
  validation {
    condition     = contains(["START", "CENTER", "END"], var.login_position)
    error_message = "Login position must be one of: START, CENTER, END"
  }
}

variable "background_asset_path" {
  description = "Path to background image asset relative to workspace root (supported: png, jpg, jpeg, svg)"
  type        = string
  default     = ""
}

variable "logo_asset_path" {
  description = "Path to logo image asset relative to workspace root (supported: png, jpg, jpeg, svg)"
  type        = string
  default     = ""
}

variable "favicon_asset_path" {
  description = "Path to favicon asset relative to workspace root (supported: ico, png)"
  type        = string
  default     = ""
}

variable "enable_google_identity_provider" {
  description = "Enable Google identity provider for Cognito User Pool"
  type        = bool
  default     = false
}

variable "google_client_id" {
  description = "Google OAuth 2.0 client ID (required when enable_google_identity_provider is true)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google OAuth 2.0 client secret (required when enable_google_identity_provider is true)"
  type        = string
  default     = ""
  sensitive   = true
}