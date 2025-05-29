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

variable "branding_assets" {
  description = "JSON string containing list of branding assets for managed login (max 15 assets)"
  type        = string
  default     = "[]"

  validation {
    condition = can(jsondecode(var.branding_assets))
    error_message = "branding_assets must be valid JSON"
  }

  validation {
    condition = length(jsondecode(var.branding_assets)) <= 15
    error_message = "Maximum of 15 branding assets allowed"
  }
}