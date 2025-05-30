# AWS Cognito Auth GitHub Action

A GitHub Action that provisions AWS Cognito User Pools for authentication using Terraform. This action creates a complete authentication setup with sensible defaults and best practices.

## Features

- 🔐 **Secure by Default**: Pre-configured with strong password policies and security settings
- 🚀 **Simple Setup**: Minimal configuration required to get started
- 🎨 **Cognito Hosted UI**: Automatically provisions Cognito's managed login interface
- ✨ **Custom Branding**: Support for AWS Cognito Managed Login branding with custom logos, colors, and settings
- 📁 **Flexible Branding Options**: Support for both inline JSON and file-based branding configurations
- 🔄 **OAuth 2.0 Support**: Full OAuth 2.0/OpenID Connect support with customizable flows
- 📱 **Multi-Platform**: Works with web, mobile, and API applications
- 🌐 **Repository Portable**: Works seamlessly across different repositories with or without branding files
- 🛡️ **Safe File Handling**: Gracefully handles missing files without errors
- 🏗️ **Infrastructure as Code**: Uses Terraform for reliable, repeatable deployments

## Quick Start

```yaml
- uses: alonch/actions-aws-auth@main
  with:
    name: my-app-auth
```

## Usage

### Basic Example

```yaml
name: Deploy Authentication
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-region: us-east-1
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          role-session-name: github-actions
      
      - uses: alonch/actions-aws-backend-setup@main
        with:
          instance: my-app
      
      - uses: alonch/actions-aws-auth@main
        with:
          name: my-app-auth
          callback_urls: "https://myapp.com/callback,https://myapp.com/auth"
          logout_urls: "https://myapp.com/logout,https://myapp.com"
```

### Advanced Example

```yaml
- uses: alonch/actions-aws-auth@main
  with:
    name: production-auth
    callback_urls: "https://app.example.com/auth/callback,https://admin.example.com/callback"
    logout_urls: "https://app.example.com,https://admin.example.com"
    action: apply
```

### Advanced Example with Managed Login Branding

**Option 1: Using JSON string for branding assets**

```yaml
- uses: alonch/actions-aws-auth@main
  with:
    name: branded-auth
    callback_urls: "https://app.example.com/auth/callback,https://admin.example.com/callback"
    logout_urls: "https://app.example.com,https://admin.example.com"
    enable_managed_login_branding: true
    branding_settings_file: "branding-settings.json"
    branding_assets: |
      [
        {
          "category": "LOGO",
          "extension": "png",
          "bytes": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
          "color_mode": "LIGHT"
        }
      ]
```

**Option 2: Using file for branding assets (recommended for multiple assets)**

```yaml
- uses: alonch/actions-aws-auth@main
  with:
    name: branded-auth-file
    callback_urls: "https://app.example.com/auth/callback,https://admin.example.com/callback"
    logout_urls: "https://app.example.com,https://admin.example.com"
    enable_managed_login_branding: true
    branding_settings_file: "config/branding-settings.json"
    branding_assets_file: "config/branding-assets.json"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `name` | Cognito User Pool name - used as the Name tag | ✅ Yes | - |
| `callback_urls` | Comma-separated list of callback URLs for OAuth | ❌ No | `https://example.com/callback` |
| `logout_urls` | Comma-separated list of logout URLs for OAuth | ❌ No | `https://example.com` |
| `enable_managed_login_branding` | Enable managed login branding for custom UI | ❌ No | `false` |
| `branding_settings_file` | Path to JSON file with branding settings | ❌ No | `""` |
| `branding_assets` | JSON array of branding assets (max 15) | ❌ No | `[]` |
| `branding_assets_file` | Path to JSON file containing branding assets | ❌ No | `""` |
| `action` | Desired outcome: `apply`, `plan`, or `destroy` | ❌ No | `apply` |

> **Note**: This action is designed to work across different repositories. All file paths are optional and the action will gracefully handle missing files without errors. If both `branding_assets` and `branding_assets_file` are provided, the file takes priority.

## Outputs

| Output | Description |
|--------|-------------|
| `user_pool_id` | ID of the Cognito User Pool |
| `user_pool_arn` | ARN of the Cognito User Pool |
| `client_id` | ID of the Cognito User Pool Client |
| `client_secret` | Secret of the Cognito User Pool Client (sensitive) |
| `cognito_domain` | Cognito provided domain URL for hosted UI |
| `managed_login_branding_enabled` | Whether managed login branding is enabled |
| `managed_login_version` | Managed login version used by the domain |
| `managed_login_branding_id` | ID of the managed login branding resource |
| `hosted_ui_url` | Complete hosted UI URL for sign-in |

## What Gets Created

This action provisions the following AWS resources:

- **Cognito User Pool** with email verification and strong password policy
- **User Pool Client** with OAuth 2.0 configuration
- **User Pool Domain** using Cognito's provided domain (e.g., `your-app-12345.auth.us-east-1.amazoncognito.com`)

### Default Configuration

- **Email Verification**: Required for new users
- **Password Policy**: Minimum 8 characters, requires uppercase, lowercase, and numbers
- **OAuth Flows**: Code and implicit flows enabled
- **OAuth Scopes**: `email`, `openid`, `profile`, `aws.cognito.signin.user.admin`
- **MFA**: Disabled by default
- **Self-Registration**: Enabled

## Using the Outputs

```yaml
- name: Deploy app with auth config
  uses: alonch/actions-aws-auth@main
  id: auth
  with:
    name: my-app-auth

- name: Configure application
  run: |
    echo "User Pool ID: ${{ steps.auth.outputs.user_pool_id }}"
    echo "Client ID: ${{ steps.auth.outputs.client_id }}"
    echo "Auth Domain: ${{ steps.auth.outputs.cognito_domain }}"
    
    # Example: Update application configuration
    aws ssm put-parameter \
      --name "/myapp/auth/user-pool-id" \
      --value "${{ steps.auth.outputs.user_pool_id }}" \
      --type "String" \
      --overwrite
```

## Authentication Flow

1. **User Registration/Login**: Users visit your app and click "Login"
2. **Redirect to Cognito**: App redirects to `${{ outputs.cognito_domain }}/login`
3. **Authentication**: User authenticates via Cognito's hosted UI
4. **Callback**: Cognito redirects back to your app with authorization code
5. **Token Exchange**: Your app exchanges code for JWT tokens

## Prerequisites

- AWS credentials configured (recommend using OIDC with `aws-actions/configure-aws-credentials`)
- Terraform backend setup (recommend using `alonch/actions-aws-backend-setup`)
- Required AWS permissions:
  - `cognito-idp:*`
  - `iam:PassRole` (if using custom roles)

## Examples

### 1. Basic Authentication (No Branding)

Standard Cognito setup with default UI styling:

```yaml
name: Deploy Basic Auth
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-region: us-east-1
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          role-session-name: github-actions
      
      - uses: alonch/actions-aws-backend-setup@main
        with:
          instance: my-app
      
      - uses: alonch/actions-aws-auth@main
        with:
          name: webapp-auth
          callback_urls: "https://myapp.com/auth/callback"
          logout_urls: "https://myapp.com"
          # enable_managed_login_branding: false (this is the default)
```

### 2. Branded Authentication with Single Asset

Custom branding with company logo:

```yaml
name: Deploy Branded Auth (Single Asset)
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-region: us-east-1
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          role-session-name: github-actions
      
      - uses: alonch/actions-aws-backend-setup@main
        with:
          instance: my-app
      
      # Encode logo file to base64 (you can do this in a separate step)
      - name: Encode logo to base64
        id: encode_logo
        run: |
          LOGO_BASE64=$(base64 -w 0 assets/company-logo.png)
          echo "logo_data=$LOGO_BASE64" >> $GITHUB_OUTPUT
        shell: bash
      
      - uses: alonch/actions-aws-auth@main
        with:
          name: branded-auth-single
          callback_urls: "https://mycompany.com/auth/callback"
          logout_urls: "https://mycompany.com"
          enable_managed_login_branding: true
          branding_settings_file: "config/branding-settings.json"
          branding_assets: |
            [
              {
                "category": "LOGO",
                "extension": "png",
                "bytes": "${{ steps.encode_logo.outputs.logo_data }}",
                "color_mode": "LIGHT"
              }
            ]
```

### 3. Full Branded Authentication with Multiple Assets

Complete branding setup with logo, favicon, and email graphics:

```yaml
name: Deploy Full Branded Auth
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-region: us-east-1
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          role-session-name: github-actions
      
      - uses: alonch/actions-aws-backend-setup@main
        with:
          instance: my-app
      
      # Encode multiple assets to base64
      - name: Encode branding assets
        id: encode_assets
        run: |
          # Light mode logo
          LOGO_LIGHT=$(base64 -w 0 assets/logo-light.png)
          echo "logo_light=$LOGO_LIGHT" >> $GITHUB_OUTPUT
          
          # Dark mode logo
          LOGO_DARK=$(base64 -w 0 assets/logo-dark.png)
          echo "logo_dark=$LOGO_DARK" >> $GITHUB_OUTPUT
          
          # Favicon
          FAVICON=$(base64 -w 0 assets/favicon.ico)
          echo "favicon=$FAVICON" >> $GITHUB_OUTPUT
          
          # Email header
          EMAIL_HEADER=$(base64 -w 0 assets/email-header.png)
          echo "email_header=$EMAIL_HEADER" >> $GITHUB_OUTPUT
          
          # Email footer
          EMAIL_FOOTER=$(base64 -w 0 assets/email-footer.png)
          echo "email_footer=$EMAIL_FOOTER" >> $GITHUB_OUTPUT
        shell: bash
      
      - uses: alonch/actions-aws-auth@main
        id: auth
        with:
          name: full-branded-auth
          callback_urls: "https://mycompany.com/auth/callback,https://app.mycompany.com/callback"
          logout_urls: "https://mycompany.com,https://app.mycompany.com"
          enable_managed_login_branding: true
          branding_settings_file: "config/company-branding.json"
          branding_assets: |
            [
              {
                "category": "LOGO",
                "extension": "png",
                "bytes": "${{ steps.encode_assets.outputs.logo_light }}",
                "color_mode": "LIGHT"
              },
              {
                "category": "LOGO",
                "extension": "png",
                "bytes": "${{ steps.encode_assets.outputs.logo_dark }}",
                "color_mode": "DARK"
              },
              {
                "category": "FAVICON",
                "extension": "ico",
                "bytes": "${{ steps.encode_assets.outputs.favicon }}",
                "color_mode": "LIGHT"
              },
              {
                "category": "EMAIL_GRAPHIC",
                "extension": "png",
                "bytes": "${{ steps.encode_assets.outputs.email_header }}",
                "color_mode": "LIGHT"
              },
              {
                "category": "EMAIL_GRAPHIC",
                "extension": "png",
                "bytes": "${{ steps.encode_assets.outputs.email_footer }}",
                "color_mode": "LIGHT"
              }
            ]

      # Use the outputs in subsequent steps
      - name: Display auth information
        run: |
          echo "🎯 Authentication Setup Complete!"
          echo "User Pool ID: ${{ steps.auth.outputs.user_pool_id }}"
          echo "Hosted UI URL: ${{ steps.auth.outputs.hosted_ui_url }}"
          echo "Branding Enabled: ${{ steps.auth.outputs.managed_login_branding_enabled }}"
          echo "Managed Login Version: ${{ steps.auth.outputs.managed_login_version }}"
        
      # Example: Store outputs in GitHub environment variables
      - name: Set deployment outputs
        run: |
          echo "COGNITO_USER_POOL_ID=${{ steps.auth.outputs.user_pool_id }}" >> $GITHUB_ENV
          echo "COGNITO_CLIENT_ID=${{ steps.auth.outputs.client_id }}" >> $GITHUB_ENV
          echo "COGNITO_DOMAIN=${{ steps.auth.outputs.cognito_domain }}" >> $GITHUB_ENV
```

### 4. Simplified File-Based Branding (Recommended)

The easiest way to manage branding with pre-created JSON files:

```yaml
name: Deploy File-Based Branded Auth
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-region: us-east-1
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          role-session-name: github-actions
      
      - uses: alonch/actions-aws-backend-setup@main
        with:
          instance: my-app
      
      - uses: alonch/actions-aws-auth@main
        id: auth
        with:
          name: file-based-branded-auth
          callback_urls: "https://mycompany.com/auth/callback"
          logout_urls: "https://mycompany.com"
          enable_managed_login_branding: true
          branding_settings_file: "branding/settings.json"
          branding_assets_file: "branding/assets.json"
      
      - name: Display results
        run: |
          echo "🎯 Branded Authentication Deployed!"
          echo "Hosted UI: ${{ steps.auth.outputs.hosted_ui_url }}"
```

**Example `branding/assets.json`:**
```json
[
  {
    "category": "LOGO",
    "extension": "png",
    "bytes": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
    "color_mode": "LIGHT"
  },
  {
    "category": "FAVICON",
    "extension": "ico", 
    "bytes": "AAABAAEAEBAAAAAAAABoBQAAFgAAACgAAAAQAAAAIAAAAAEACAAAAAAAAAEAAAAAAAAAAAAAAAEAAAAAAAAAAAAA",
    "color_mode": "LIGHT"
  }
]
```

**Example `branding/settings.json`:**
```json
{
  "displayName": "My Company Portal",
  "style": {
    "primaryColor": "#007bff",
    "backgroundColor": "#ffffff",
    "buttonColor": "#007bff"
  },
  "branding": {
    "headerText": "Welcome to My Company",
    "footerText": "© 2024 My Company Inc."
  }
}
```

> **✅ Repository Portability**: This action works seamlessly across different repositories. If the branding files don't exist in a repository, the action will simply use default Cognito styling without errors.

## Branding Configuration Options

This action provides flexible ways to configure branding for your Cognito authentication:

### 1. No Branding (Default)
- Set `enable_managed_login_branding: false` or omit it entirely
- Uses standard Cognito UI with AWS default styling
- Works in any repository without additional files

### 2. Settings Only
- Use `branding_settings_file` to customize colors, text, and styling
- No custom assets (logos, icons) required
- Lightweight branding approach

### 3. Full Branding with Inline Assets
- Use `branding_assets` parameter with base64-encoded asset data
- Suitable for simple setups with few assets
- All configuration in the workflow file

### 4. Full Branding with File Assets (Recommended)
- Use `branding_assets_file` parameter pointing to a JSON file
- Better for complex branding with multiple assets
- Easier to maintain and version control
- **File safety**: Action gracefully handles missing files

### File Priority
When both `branding_assets` and `branding_assets_file` are provided, the file takes priority for better maintainability.

## Troubleshooting

### Common Issues

1. **Invalid Callback URL**: Ensure your callback URLs are properly formatted and accessible
2. **CORS Issues**: Configure CORS in your application to allow requests from the Cognito domain
3. **Token Validation**: Use AWS SDKs or JWT libraries to validate tokens from Cognito
4. **Missing Branding Files**: The action gracefully handles missing branding files - if a file doesn't exist, default values are used instead of failing
5. **Invalid JSON in Branding Files**: Ensure your branding JSON files are properly formatted. Use online JSON validators if needed
6. **Branding Assets Size Limits**: Each asset must be under 2MB, and maximum 15 assets total are allowed

### File-Related Issues

**Q: My branding files exist but the action says they don't**
- Ensure file paths are relative to your repository root
- Check file names and extensions match exactly
- Verify files are committed to your repository

**Q: Can I use this action in repos without branding files?**
- Yes! The action is designed to work across different repositories
- Missing branding files are handled gracefully
- The action will use default Cognito styling if files are missing

**Q: Which branding approach should I use?**
- For simple setups: Use `branding_assets` parameter
- For complex/multiple assets: Use `branding_assets_file` parameter
- For maximum portability: Use file-based approach with files committed to repo

### Debugging

Enable debug output by setting the `ACTIONS_STEP_DEBUG` secret to `true` in your repository.

## Security Considerations

- **Client Secret**: The client secret is marked as sensitive and should be stored securely
- **HTTPS Required**: Callback URLs must use HTTPS in production
- **Token Validation**: Always validate JWT tokens on your backend
- **Scope Limitation**: Only request the OAuth scopes your application needs

## Limitations

- **Custom Domains**: This action uses Cognito's provided domain. Custom domains require additional setup
- **Advanced Branding**: Uses default Cognito UI styling (custom branding requires CloudFormation)
- **Region**: Resources are created in the AWS region specified in your credentials
- **Branding Assets**: Limited to 15 assets with 2MB maximum size per asset

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Managed Login Branding

### Overview

AWS Cognito Managed Login provides advanced customization options for your authentication UI, allowing you to:

- Custom logos and favicons
- Brand colors and styling
- Custom email templates
- Company branding elements
- Responsive design for all devices

### Setting Up Branding

1. **Create a branding settings JSON file**:

```json
{
  "displayName": "My Company Portal",
  "style": {
    "primaryColor": "#007bff",
    "backgroundColor": "#ffffff",
    "buttonColor": "#007bff"
  },
  "branding": {
    "headerText": "Welcome to My Company",
    "footerText": "© 2024 My Company Inc."
  }
}
```

2. **Prepare your assets** (logos, icons, etc.) in your repository

3. **Configure the action**:

```yaml
- uses: alonch/actions-aws-auth@main
  with:
    name: branded-auth
    enable_managed_login_branding: true
    branding_settings_file: "branding-settings.json"
    branding_assets: |
      [
        {
          "category": "LOGO",
          "extension": "png", 
          "bytes": "${{ base64_encode_file('assets/logo.png') }}",
          "color_mode": "LIGHT"
        },
        {
          "category": "FAVICON",
          "extension": "ico",
          "bytes": "${{ base64_encode_file('assets/favicon.ico') }}",
          "color_mode": "LIGHT"
        }
      ]
```

### Branding Assets

Supported asset categories:
- `LOGO` - Your company logo
- `FAVICON` - Browser favicon
- `EMAIL_GRAPHIC` - Email template graphics
- `SMS_GRAPHIC` - SMS template graphics
- Various email and SMS templates

**Requirements**:
- Maximum 15 assets total
- Maximum 2MB per asset
- Supported formats: PNG, JPG, JPEG, ICO, SVG
- Color modes: `LIGHT` or `DARK`

### Example Branding Configuration

See the `branding-assets-example.tf` file for complete examples of how to structure your branding configuration.
