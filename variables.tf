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
  description = "Enable managed login branding for Cognito UI customization"
  type        = bool
  default     = false
}

variable "branding_settings_file" {
  description = "Path to JSON file containing branding settings for managed login"
  type        = string
  default     = ""
}

variable "branding_assets_file" {
  description = "Path to JSON file containing branding assets for managed login (automatically generated from assets/)"
  type        = string
  default     = ""
}