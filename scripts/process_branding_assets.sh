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

# Function to process images in a directory
process_directory() {
    local dir_path="$1"
    local category="$2"
    local color_mode="$3"
    
    if [ ! -d "$dir_path" ]; then
        echo "Directory $dir_path not found, skipping $category assets"
        return
    fi
    
    echo "Scanning directory: $dir_path"
    
    # Find all image files in the directory and process them
    while IFS= read -r -d '' file_path; do
        if [ -f "$file_path" ]; then
            # Get file extension and convert to uppercase
            extension=$(basename "$file_path" | sed 's/.*\.//' | tr '[:lower:]' '[:upper:]')
            
            # Handle JPEG files - AWS expects "JPG" not "JPEG"
            if [ "$extension" = "JPEG" ]; then
                extension="JPG"
            fi
            
            echo "Found image: $(basename "$file_path") with extension: $extension"
            add_asset "$category" "$extension" "$file_path" "$color_mode"
        fi
    done < <(find "$dir_path" -maxdepth 1 -type f \( \
        -iname "*.png" -o \
        -iname "*.jpg" -o \
        -iname "*.jpeg" -o \
        -iname "*.ico" -o \
        -iname "*.svg" \
    \) -print0)
}

# Ensure jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed"
    exit 1
fi

# Process assets from different directories
echo "Searching for branding assets in standard directories..."

# Process background images
process_directory "$WORKSPACE_PATH/assets/background" "PAGE_BACKGROUND" "LIGHT"

# Process favicon images  
process_directory "$WORKSPACE_PATH/assets/favicon" "FAVICON_ICO" "LIGHT"

# Process logo images
process_directory "$WORKSPACE_PATH/assets/logo" "FORM_LOGO" "LIGHT"

# Write the final JSON array to file
echo "$ASSETS" | jq '.' > "$OUTPUT_FILE"

echo "Branding assets processed and saved to $OUTPUT_FILE"
echo "Generated $(echo "$ASSETS" | jq 'length') assets" 