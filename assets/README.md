# Branding Assets Directory

This directory contains the branding assets for your Cognito Managed Login configuration.

## Automatic Asset Processing

When `enable_managed_login_branding` is set to `true`, the action will automatically process images from these specific paths:

```
assets/
├── background/
│   └── image.png      # → PAGE_BACKGROUND (PNG format)
├── favicon/
│   └── image.ico      # → FAVICON_ICO (ICO format)
└── logo/
    └── image.png      # → FORM_LOGO (PNG format)
```

Simply place your images in these exact paths and the action will:
- Automatically convert them to base64
- Create the required JSON structure
- Apply them to your Cognito branding

## File Requirements

- **Background Image**: `assets/background/image.png`
  - Recommended size: 1920x1080px or larger
  - Format: PNG
  - Category: PAGE_BACKGROUND

- **Favicon**: `assets/favicon/image.ico`
  - Recommended size: 32x32px
  - Format: ICO
  - Category: FAVICON_ICO

- **Logo**: `assets/logo/image.png`
  - Recommended size: 200x50px
  - Format: PNG
  - Category: FORM_LOGO

## File Constraints

- **Maximum file size**: 2MB per asset
- **Color mode**: All assets use "LIGHT" mode by default
- **Missing files**: The action gracefully handles missing files - only available assets will be processed

## Example Usage

### Simple Setup

Just add your images to the correct paths:

```yaml
- uses: alonch/actions-aws-auth@main
  with:
    name: my-app-auth
    enable_managed_login_branding: true
    branding_settings_file: "config/branding-settings.json"
```

### Generated JSON Structure

The action automatically creates this JSON structure from your images:

```json
[
  {
    "category": "PAGE_BACKGROUND",
    "extension": "PNG",
    "bytes": "base64-encoded-content-here",
    "color_mode": "LIGHT"
  },
  {
    "category": "FAVICON_ICO",
    "extension": "ICO",
    "bytes": "base64-encoded-content-here",
    "color_mode": "LIGHT"
  },
  {
    "category": "FORM_LOGO",
    "extension": "PNG",
    "bytes": "base64-encoded-content-here",
    "color_mode": "LIGHT"
  }
]
```

## Repository Portability

This structure works across different repositories:
- Missing assets are handled gracefully
- No errors if directories don't exist
- Repositories without branding assets will use default Cognito styling

## Migration from Manual Setup

If you're migrating from manual asset management:

1. Move your images to the new standard paths
2. Remove manual `branding_assets` or `branding_assets_file` parameters
3. Set `enable_managed_login_branding: true`
4. The action will handle the rest automatically

## Troubleshooting

- **File not found**: Ensure exact paths and filenames match the requirements
- **Invalid format**: Check that background and logo are PNG, favicon is ICO
- **File too large**: Ensure each file is under 2MB
- **Repository structure**: Verify the `assets/` directory is in your repository root

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