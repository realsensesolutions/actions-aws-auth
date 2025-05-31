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

variable "branding_settings_file" {
  description = "Path to JSON file containing branding settings for managed login"
  type        = string
  default     = ""
}

variable "assets_base_path" {
  description = "Base path where to look for assets/ directory. Defaults to current working directory"
  type        = string
  default     = ""
}