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

**Option 1: Using automatic branding with custom login position**

```yaml
- uses: alonch/actions-aws-auth@main
  with:
    name: branded-auth
    callback_urls: "https://app.example.com/auth/callback,https://admin.example.com/callback"
    logout_urls: "https://app.example.com,https://admin.example.com"
    enable_managed_login_branding: true
    login_position: "START"
```

**Option 2: Using default center position (recommended)**

```yaml
- uses: alonch/actions-aws-auth@main
  with:
    name: branded-auth-file
    callback_urls: "https://app.example.com/auth/callback,https://admin.example.com/callback"
    logout_urls: "https://app.example.com,https://admin.example.com"
    enable_managed_login_branding: true
    login_position: "CENTER"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `name` | Cognito User Pool name - used as the Name tag | ✅ Yes | - |
| `callback_urls` | Comma-separated list of callback URLs for OAuth | ❌ No | `https://example.com/callback` |
| `logout_urls` | Comma-separated list of logout URLs for OAuth | ❌ No | `https://example.com` |
| `enable_managed_login_branding` | Enable managed login branding for custom UI | ❌ No | `false` |
| `login_position` | Login form horizontal position: START, CENTER, or END | ❌ No | `CENTER` |
| `action` | Desired outcome: `apply`, `plan`, or `destroy` | ❌ No | `apply` |
| `enable_google_identity_provider` | Enable Google identity provider for Cognito User Pool | ❌ No | `false` |
| `google_client_id` | Google OAuth 2.0 client ID (required when enable_google_identity_provider is true) | ❌ No | `""` |
| `google_client_secret` | Google OAuth 2.0 client secret (required when enable_google_identity_provider is true) | ❌ No | `""` |

## Google Identity Provider Integration

This action supports integrating Google as an identity provider, allowing users to sign in with their Google accounts. When enabled, users can authenticate using both Cognito credentials and Google accounts.

### Setup Google OAuth 2.0

Before enabling Google identity provider, you need to set up OAuth 2.0 credentials in Google Cloud Console:

1. **Go to Google Cloud Console**: Visit [Google Cloud Console](https://console.cloud.google.com/)
2. **Create/Select Project**: Create a new project or select an existing one
3. **Enable Google+ API**: Navigate to "APIs & Services" > "Library" and enable the Google+ API
4. **Create OAuth 2.0 Credentials**:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth 2.0 Client IDs"
   - Set application type to "Web application"
   - Add authorized redirect URIs using your Cognito domain:
     ```
     https://YOUR-COGNITO-DOMAIN.auth.REGION.amazoncognito.com/oauth2/idpresponse
     ```

### Usage Example

```yaml
- uses: alonch/actions-aws-auth@main
  with:
    name: my-app-auth
    callback_urls: "https://myapp.com/auth/callback"
    logout_urls: "https://myapp.com"
    enable_google_identity_provider: true
    google_client_id: ${{ secrets.GOOGLE_CLIENT_ID }}
    google_client_secret: ${{ secrets.GOOGLE_CLIENT_SECRET }}
```

### Configuration Details

When Google identity provider is enabled:

- **Supported Identity Providers**: The user pool client supports both "COGNITO" and "Google"
- **OAuth Scopes**: Google integration includes `email`, `openid`, and `profile` scopes
- **Attribute Mapping**: Automatically maps Google user attributes:
  - `email` → Cognito email
  - `sub` → Cognito username  
  - `given_name` → Cognito given_name
  - `family_name` → Cognito family_name
  - `picture` → Cognito picture

### Security Considerations

- Store Google OAuth credentials as GitHub secrets for security
- The `google_client_id` and `google_client_secret` are marked as sensitive
- Ensure your Google OAuth redirect URIs match your Cognito domain exactly
- Both credentials are required when `enable_google_identity_provider` is set to `true`

### Authentication Flow with Google

1. **User initiates login**: User visits your Cognito hosted UI
2. **Provider selection**: User can choose between Cognito credentials or "Sign in with Google"
3. **Google authentication**: If Google is selected, user is redirected to Google's OAuth flow
4. **Authorization**: User authorizes your application in Google
5. **Token exchange**: Google redirects back to Cognito with authorization code
6. **User creation/login**: Cognito creates/updates user account and issues JWT tokens
7. **App callback**: User is redirected to your application with Cognito tokens

> **Note**: When `enable_managed_login_branding` is true, the action will automatically process image files from your repository in these directories:
> - `assets/background/` → PAGE_BACKGROUND (PNG, JPG, JPEG, SVG files)
> - `assets/favicon/` → FAVICON_ICO (ICO, PNG files)  
> - `assets/logo/` → FORM_LOGO (PNG, JPG, JPEG, SVG files)
> 
> Any filename is supported in each directory. The action will gracefully handle missing directories without errors.
> The `login_position` parameter only works when `enable_managed_login_branding` is true.

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
| `google_identity_provider_enabled` | Whether Google identity provider is enabled |
| `google_identity_provider_name` | Name of the Google identity provider (if enabled) |
| `supported_identity_providers` | List of supported identity providers |

## What Gets Created

This action provisions the following AWS resources:

- **Cognito User Pool** with email verification and strong password policy
- **User Pool Client** with OAuth 2.0 configuration
- **User Pool Domain** using Cognito's provided domain (e.g., `your-app-12345.auth.us-east-1.amazoncognito.com`)
- **Google Identity Provider** (optional) for Google OAuth 2.0 integration

### Default Configuration

- **Email Verification**: Required for new users
- **Password Policy**: Minimum 8 characters, requires uppercase, lowercase, and numbers
- **OAuth Flows**: Code and implicit flows enabled
- **OAuth Scopes**: `email`, `openid`, `profile`, `aws.cognito.signin.user.admin`
- **MFA**: Disabled by default
- **Self-Registration**: Enabled

### Custom Attributes

The user pool includes the following custom attributes available in JWT tokens: `custom:tenantId`, `custom:userRole`, `custom:apiKey`, `custom:tenantTier`, and `custom:serviceProviderId`.

**Go Example:**
```go
type CognitoClaims struct {
    ServiceProviderID string `json:"custom:serviceProviderId"`
    // ... other attributes
}
```

**Note:** New user pools automatically include all attributes. Existing pools continue working safely. To add `serviceProviderId` to an existing pool, use:
```bash
aws cognito-idp add-custom-attributes \
  --user-pool-id <your-pool-id> \
  --custom-attributes '[{"Name":"serviceProviderId","AttributeDataType":"String","Mutable":true}]'
```

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

### 2. Automatic Branding with Standard Paths (Recommended)

The simplest way to add branding - just place your images in the expected paths:

```yaml
name: Deploy Auto-Branded Auth
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
          name: auto-branded-auth
          callback_urls: "https://mycompany.com/auth/callback"
          logout_urls: "https://mycompany.com"
          enable_managed_login_branding: true
          login_position: "CENTER"
```

**Required directory structure:**
```
your-repo/
├── assets/
│   ├── background/
│   │   └── [any image file]      # → PAGE_BACKGROUND (PNG, JPG, JPEG, SVG formats)
│   ├── favicon/
│   │   └── [any image file]      # → FAVICON_ICO (ICO, PNG files)
│   └── logo/
│       └── [any image file]      # → FORM_LOGO (PNG, JPG, JPEG, SVG files)
└── config/
    └── branding-settings.json
```

The action will automatically:
- Scan directories for any image files (flexible naming)
- Detect and convert your images to base64
- Determine the correct file extension and format
- Create the branding assets JSON
- Apply the branding to your Cognito setup

**Supported file formats:**
- PNG, JPG, JPEG, SVG files for backgrounds and logos
- ICO, PNG files for favicons
- Any filename is supported - no need for specific names

**Examples of valid structures:**
```
your-repo/assets/
├── background/
│   └── company-bg.png
├── favicon/  
│   └── site-icon.ico
└── logo/
    └── brand-logo.svg
```

```
your-repo/assets/
├── background/
│   └── hero-image.jpg
├── favicon/
│   └── favicon.png
└── logo/
    └── my-company.png
```

### 3. Authentication with Google Identity Provider

Enable Google authentication alongside Cognito credentials:

```yaml
name: Deploy Google Auth
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
          name: google-auth
          callback_urls: "https://myapp.com/auth/callback"
          logout_urls: "https://myapp.com"
          enable_google_identity_provider: true
          google_client_id: ${{ secrets.GOOGLE_CLIENT_ID }}
          google_client_secret: ${{ secrets.GOOGLE_CLIENT_SECRET }}
```

**Prerequisites for Google Authentication:**
1. Set up OAuth 2.0 credentials in Google Cloud Console
2. Add your Cognito domain to Google OAuth authorized redirect URIs
3. Store Google credentials as GitHub repository secrets
4. Enable Google+ API in Google Cloud Console

### 4. Advanced Manual Branding (Legacy)

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
          login_position: "END"
      
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
- Use `login_position` parameter to customize form positioning: START, CENTER, or END
- Works with automatic branding asset discovery from assets/ directory
- Lightweight positioning approach

### 3. Full Branding with Automatic Asset Discovery (Recommended)
- Set `enable_managed_login_branding: true` to enable automatic asset scanning
- Use `login_position` parameter to position the login form
- Place your images in assets/background/, assets/favicon/, assets/logo/ directories
- Action automatically handles file discovery and conversion

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
    login_position: "CENTER"
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
