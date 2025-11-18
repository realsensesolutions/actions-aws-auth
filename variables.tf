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

variable "idp" {
  description = "List of identity providers to enable (space or newline separated). Supported values: 'google', 'cognito'"
  type        = string
  default     = "cognito"
  
  validation {
    condition = alltrue([
      for provider in split("\n", replace(var.idp, " ", "\n")) :
      contains(["google", "cognito", ""], lower(trimspace(provider)))
    ])
    error_message = "Identity providers must be one or more of: 'google', 'cognito' (case insensitive)."
  }
}

variable "google_client_id" {
  description = "Google OAuth 2.0 client ID (required when idp includes 'google')"
  type        = string
  default     = ""
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google OAuth 2.0 client secret (required when idp includes 'google')"
  type        = string
  default     = ""
  sensitive   = true
}

variable "self_registration" {
  description = "Allow users to sign themselves up (true) or require admin to create users (false)"
  type        = bool
  default     = true
}

variable "admin_email" {
  description = "Email address for the admin user (if provided, admin user will be created automatically)"
  type        = string
  default     = ""

  validation {
    condition = var.admin_email == "" || can(regex("^[\\w\\.-]+@[\\w\\.-]+\\.[a-zA-Z]{2,}$", var.admin_email))
    error_message = "admin_email must be a valid email address or empty."
  }
}

variable "case_sensitive" {
  description = "Whether usernames are case sensitive (true) or case insensitive (false). Default is false (case insensitive)"
  type        = bool
  default     = false
}