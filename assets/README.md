# Branding Assets Directory

This directory contains the branding assets for your Cognito Managed Login configuration.

## Supported Asset Types

### Logos
- `logo-light.png` - Logo for light mode (recommended size: 200x50px)
- `logo-dark.png` - Logo for dark mode (recommended size: 200x50px)

### Favicon
- `favicon.ico` - Favicon for the login page (recommended size: 32x32px)

### Email Graphics
- `email-header.png` - Header graphic for email templates (recommended size: 600x100px)

### SMS Graphics
- `sms-graphic.png` - Graphic for SMS templates (recommended size: 300x100px)

## File Requirements

- **Maximum file size**: 2MB per asset
- **Maximum total assets**: 15 files
- **Supported formats**: PNG, JPG, JPEG, ICO, SVG
- **Color modes**: Each asset must specify either "LIGHT" or "DARK" mode

## Asset Categories

The following categories are supported:
- `FAVICON`
- `LOGO`
- `EMAIL_GRAPHIC`
- `SMS_GRAPHIC`
- `EMAIL_TEMPLATE`
- `SMS_TEMPLATE`
- `PASSWORD_RESET_EMAIL_TEMPLATE`
- `PASSWORD_RESET_SMS_TEMPLATE`
- `MFA_EMAIL_TEMPLATE`
- `MFA_SMS_TEMPLATE`

## Example Usage

For Terraform module usage:

```hcl
branding_assets = jsonencode([
  {
    category   = "LOGO"
    extension  = "png"
    bytes      = filebase64("${path.module}/assets/logo-light.png")
    color_mode = "LIGHT"
  },
  {
    category   = "FAVICON"
    extension  = "ico"
    bytes      = filebase64("${path.module}/assets/favicon.ico")
    color_mode = "LIGHT"
  }
])
```

For GitHub Actions usage:

```yaml
branding_assets: |
  [
    {
      "category": "LOGO",
      "extension": "png",
      "bytes": "base64-encoded-content-here",
      "color_mode": "LIGHT"
    },
    {
      "category": "FAVICON",
      "extension": "ico", 
      "bytes": "base64-encoded-content-here",
      "color_mode": "LIGHT"
    }
  ]
```

## Note

These files will be base64 encoded automatically by Terraform using the `filebase64()` function. Make sure your files are optimized for web use to keep the encoded size manageable. 