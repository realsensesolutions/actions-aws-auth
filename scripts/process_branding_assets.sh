#!/bin/bash

set -e

# Check if we should process branding assets
if [ "$1" != "true" ]; then
    echo "Managed login branding is disabled, skipping asset processing"
    exit 0
fi

WORKSPACE_PATH="$2"
OUTPUT_FILE="$WORKSPACE_PATH/.branding_assets.json"

echo "Processing branding assets from workspace: $WORKSPACE_PATH"

# Initialize empty array
ASSETS="[]"

# Function to add asset to JSON array
add_asset() {
    local category="$1"
    local extension="$2"
    local file_path="$3"
    local color_mode="$4"
    
    if [ -f "$file_path" ]; then
        echo "Processing $file_path for category $category"
        
        # Convert image to base64
        local base64_content
        if command -v base64 >/dev/null 2>&1; then
            # Linux/macOS base64 command
            base64_content=$(base64 -w 0 < "$file_path" 2>/dev/null || base64 < "$file_path" | tr -d '\n')
        else
            echo "Error: base64 command not found"
            exit 1
        fi
        
        # Create JSON object for this asset
        local asset_json=$(cat << EOF
{
  "category": "$category",
  "extension": "$extension",
  "bytes": "$base64_content",
  "color_mode": "$color_mode"
}
EOF
)
        
        # Add to assets array
        ASSETS=$(echo "$ASSETS" | jq ". += [$asset_json]")
        echo "Added $category asset"
    else
        echo "Warning: $file_path not found, skipping $category asset"
    fi
}

# Ensure jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed"
    exit 1
fi

# Process specific assets according to user requirements
add_asset "PAGE_BACKGROUND" "PNG" "$WORKSPACE_PATH/assets/background/image.png" "LIGHT"
add_asset "FAVICON_ICO" "ICO" "$WORKSPACE_PATH/assets/favicon/image.ico" "LIGHT"
add_asset "FORM_LOGO" "PNG" "$WORKSPACE_PATH/assets/logo/image.png" "LIGHT"

# Write the final JSON array to file
echo "$ASSETS" | jq '.' > "$OUTPUT_FILE"

echo "Branding assets processed and saved to $OUTPUT_FILE"
echo "Generated $(echo "$ASSETS" | jq 'length') assets" 