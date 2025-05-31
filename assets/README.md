# Branding Assets Directory

This directory contains the branding assets for your Cognito Managed Login configuration.

## Automatic Asset Processing

When `enable_managed_login_branding` is set to `true`, the action will automatically process any image files found in these directories:

```
assets/
├── background/
│   └── [any image file]    # → PAGE_BACKGROUND (PNG, JPG, JPEG, SVG formats)
├── favicon/
│   └── [any image file]    # → FAVICON_ICO (ICO, PNG formats)
└── logo/
    └── [any image file]    # → FORM_LOGO (PNG, JPG, JPEG, SVG formats)
```

Simply place your images in these directories with any filename and the action will:
- Automatically detect and convert them to base64
- Determine the correct file extension and format
- Create the required JSON structure  
- Apply them to your Cognito branding

## File Requirements

The script automatically scans for image files with these extensions:
- **PNG** files (`.png`)
- **JPEG/JPG** files (`.jpg`, `.jpeg`) 
- **ICO** files (`.ico`)
- **SVG** files (`.svg`)

### Directory Structure
- **Background Images**: `assets/background/`
  - Any PNG, JPG, JPEG, or SVG file
  - Category: PAGE_BACKGROUND

- **Favicon**: `assets/favicon/`
  - Any ICO or PNG file
  - Category: FAVICON_ICO

- **Logo**: `assets/logo/`
  - Any PNG, JPG, JPEG, or SVG file
  - Category: FORM_LOGO

## File Constraints

- **Maximum file size**: 2MB per asset
- **Color mode**: All assets use "LIGHT" mode by default
- **Missing directories**: The action gracefully handles missing directories - only available assets will be processed
- **Multiple files**: If multiple images are found in a directory, all will be processed

## Example Usage

### Simple Setup

Just add your images to the correct directories with any names:

```
assets/
├── background/
│   └── company-background.png
├── favicon/
│   └── my-favicon.ico
└── logo/
    └── company-logo.png
```

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
- Missing assets or directories are handled gracefully
- No errors if directories don't exist
- Repositories without branding assets will use default Cognito styling
- Flexible file naming - use any names you prefer

## Migration from Manual Setup

If you're migrating from manual asset management:

1. Move your images to the new directory structure (any filenames are fine)
2. Remove manual `branding_assets` or `branding_assets_file` parameters
3. Set `enable_managed_login_branding: true`
4. The action will handle the rest automatically

## Troubleshooting

- **Directory not found**: Create the directory structure if it doesn't exist
- **Invalid format**: Ensure files are in supported formats (PNG, JPG, JPEG, ICO, SVG)
- **File too large**: Ensure each file is under 2MB
- **Repository structure**: Verify the `assets/` directory is in your repository root
- **Multiple files**: If you have multiple files in one directory, all will be processed

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