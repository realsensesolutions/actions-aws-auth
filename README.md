# AWS Cognito Auth GitHub Action

A GitHub Action that provisions AWS Cognito User Pools for authentication using Terraform. This action creates a complete authentication setup with sensible defaults and best practices.

## Features

- 🔐 **Secure by Default**: Pre-configured with strong password policies and security settings
- 🚀 **Simple Setup**: Minimal configuration required to get started
- 🎨 **Cognito Authentication**: Direct integration with Cognito's authentication endpoints
- 🔄 **OAuth 2.0 Support**: Full OAuth 2.0/OpenID Connect support with customizable flows
- 📱 **Multi-Platform**: Works with web, mobile, and API applications
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

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `name` | Cognito User Pool name - used as the Name tag | ✅ Yes | - |
| `callback_urls` | Comma-separated list of callback URLs for OAuth | ❌ No | `https://example.com/callback` |
| `logout_urls` | Comma-separated list of logout URLs for OAuth | ❌ No | `https://example.com` |
| `action` | Desired outcome: `apply`, `plan`, or `destroy` | ❌ No | `apply` |

## Outputs

| Output | Description |
|--------|-------------|
| `user_pool_id` | ID of the Cognito User Pool |
| `user_pool_arn` | ARN of the Cognito User Pool |
| `client_id` | ID of the Cognito User Pool Client |
| `client_secret` | Secret of the Cognito User Pool Client (sensitive) |
| `cognito_domain` | Cognito endpoint URL (e.g., https://cognito-idp.us-east-1.amazonaws.com/us-east-1_userPoolId) |

## What Gets Created

This action provisions the following AWS resources:

- **Cognito User Pool** with email verification and strong password policy
- **User Pool Client** with OAuth 2.0 configuration

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
2. **Redirect to Cognito**: App redirects to the Cognito authentication endpoint
3. **Authentication**: User authenticates via Cognito
4. **Callback**: Cognito redirects back to your app with authorization code
5. **Token Exchange**: Your app exchanges code for JWT tokens

## Prerequisites

- AWS credentials configured (recommend using OIDC with `aws-actions/configure-aws-credentials`)
- Terraform backend setup (recommend using `alonch/actions-aws-backend-setup`)
- Required AWS permissions:
  - `cognito-idp:*`
  - `iam:PassRole` (if using custom roles)

## Examples

### Web Application

```yaml
- uses: alonch/actions-aws-auth@main
  with:
    name: webapp-auth
    callback_urls: "https://myapp.com/auth/callback"
    logout_urls: "https://myapp.com"
```

### Mobile + Web Application

```yaml
- uses: alonch/actions-aws-auth@main
  with:
    name: multiplatform-auth
    callback_urls: "https://myapp.com/callback,myapp://auth/callback"
    logout_urls: "https://myapp.com,myapp://logout"
```

### Development Environment

```yaml
- uses: alonch/actions-aws-auth@main
  with:
    name: dev-auth
    callback_urls: "http://localhost:3000/callback,http://localhost:8080/auth"
    logout_urls: "http://localhost:3000,http://localhost:8080"
```

## Troubleshooting

### Common Issues

1. **Invalid Callback URL**: Ensure your callback URLs are properly formatted and accessible
2. **CORS Issues**: Configure CORS in your application to allow requests from the Cognito domain
3. **Token Validation**: Use AWS SDKs or JWT libraries to validate tokens from Cognito

### Debugging

Enable debug output by setting the `ACTIONS_STEP_DEBUG` secret to `true` in your repository.

## Security Considerations

- **Client Secret**: The client secret is marked as sensitive and should be stored securely
- **HTTPS Required**: Callback URLs must use HTTPS in production
- **Token Validation**: Always validate JWT tokens on your backend
- **Scope Limitation**: Only request the OAuth scopes your application needs

## Limitations

- **Custom Domains**: This action uses the direct Cognito endpoint URL
- **Advanced Branding**: Uses default Cognito authentication flow
- **Region**: Resources are created in the AWS region specified in your credentials

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
