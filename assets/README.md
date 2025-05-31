# Branding Assets Directory

This directory contains the branding assets for your Cognito Managed Login configuration.

## Automatic Asset Processing with Terraform

When `enable_managed_login_branding` is set to `true`, the action automatically uses Terraform's `filebase64()` function to process any image files found in these directories:

```
assets/
├── background/
│   └── [any image file]    # → PAGE_BACKGROUND (PNG, JPG, JPEG, SVG formats)
├── favicon/
│   └── [any image file]    # → FAVICON_ICO (ICO, PNG formats)
└── logo/
    └── [any image file]    # → FORM_LOGO (PNG, JPG, JPEG, SVG formats)
```

The action uses Terraform's native functions to:
- Automatically discover images using `fileset()` 
- Convert them to base64 using `filebase64()`
- Determine the correct file extension and format
- Create the required JSON structure for AWS Cognito
- Apply them to your Cognito branding

## File Requirements

Terraform automatically scans for image files with these extensions:
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

## Repository Portability

This structure works seamlessly across different repositories:
- **Cross-repository support**: Works in any repository that uses this action
- **Flexible naming**: Use any filename for your images
- **Graceful handling**: Missing directories or files don't cause errors
- **No dependencies**: Pure Terraform implementation, no external scripts
- **Automatic detection**: Terraform discovers assets at plan/apply time

## File Constraints

- **Maximum file size**: 2MB per asset (AWS limitation)
- **Color mode**: All assets use "LIGHT" mode by default
- **Missing directories**: Terraform gracefully handles missing directories
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
    └── company-logo.svg
```

```yaml
- uses: your-org/actions-aws-auth@main
  with:
    name: my-app-auth
    enable_managed_login_branding: true
    login_position: "CENTER"
```

### Terraform Native Processing

The action automatically creates this structure using Terraform:

```hcl
# Terraform automatically discovers and processes assets
locals {
  discovered_assets = flatten([
    for dir_name, category in local.asset_directories : [
      for ext in local.supported_extensions[dir_name] : [
        for file_path in try(fileset("${var.assets_base_path}/assets/${dir_name}", "*.${ext}"), []) : {
          category   = category
          extension  = upper(ext == "jpg" ? "jpeg" : ext)
          bytes      = filebase64("${var.assets_base_path}/assets/${dir_name}/${file_path}")
          color_mode = "LIGHT"
          file_path  = "${dir_name}/${file_path}"
        }
      ]
    ]
  ])
}
```

### Generated Output

View discovered assets in the action output:

```json
{
  "asset_count": 3,
  "assets": [
    {
      "category": "PAGE_BACKGROUND",
      "extension": "PNG",
      "file_path": "background/company-background.png",
      "size_kb": 45.2
    },
    {
      "category": "FAVICON_ICO", 
      "extension": "ICO",
      "file_path": "favicon/my-favicon.ico",
      "size_kb": 12.8
    },
    {
      "category": "FORM_LOGO",
      "extension": "SVG", 
      "file_path": "logo/company-logo.svg",
      "size_kb": 8.5
    }
  ]
}
```

## Benefits of Terraform Implementation

### Native Processing
- **No external dependencies**: Uses only Terraform built-in functions
- **Better error handling**: Terraform validates files at plan time
- **Consistent behavior**: Same processing across all environments

### Performance
- **Faster execution**: No shell scripts or external tools
- **Efficient scanning**: Terraform's `fileset()` is optimized for file discovery
- **Parallel processing**: Terraform handles multiple files efficiently

### Reliability
- **Type safety**: Terraform validates file types and structures
- **Plan-time validation**: Catch issues before applying changes
- **Idempotent**: Consistent results across multiple runs

## Troubleshooting

### Common Issues
- **Directory not found**: Create the `assets/` directory structure in your repository root
- **Invalid format**: Ensure files are in supported formats (PNG, JPG, JPEG, ICO, SVG)
- **File too large**: Ensure each file is under 2MB
- **Permission errors**: Verify file permissions in your repository

### Debugging Assets
Check the `discovered_branding_assets` output to see what Terraform found:
- Asset count and file paths
- File sizes in KB
- Categories and extensions
- Any processing errors

### Terraform Plan
Run `terraform plan` to see what assets will be processed:
```bash
# The plan will show discovered assets
terraform plan -var="assets_base_path=/path/to/your/repo"
```

## Migration from Script-based Approach

If migrating from the previous shell script approach:

1. **Remove manual configurations**: No need for `branding_assets_file` parameter
2. **Use standard structure**: Place images in the expected directories
3. **Enable branding**: Set `enable_managed_login_branding: true`
4. **Terraform handles the rest**: No additional configuration needed

## Advanced Configuration

### Custom Asset Base Path
For non-standard repository structures:

```yaml
- uses: your-org/actions-aws-auth@main
  with:
    name: my-app-auth
    enable_managed_login_branding: true
    # Terraform will look for assets at: custom/path/assets/
```

### Multiple Environments
Assets are discovered per Terraform workspace:

```yaml
# Production
- uses: your-org/actions-aws-auth@main
  with:
    name: myapp-prod
    enable_managed_login_branding: true

# Staging  
- uses: your-org/actions-aws-auth@main
  with:
    name: myapp-staging
    enable_managed_login_branding: true
```

Each deployment will use the same assets from your repository, ensuring consistency across environments.

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