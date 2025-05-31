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
        
        # Check file size (2MB limit)
        local file_size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null)
        if [ "$file_size" -gt 2097152 ]; then
            echo "Warning: $file_path is larger than 2MB ($file_size bytes), skipping"
            return
        fi
        
        # Convert image to base64
        local base64_content
        if command -v base64 >/dev/null 2>&1; then
            # Linux/macOS base64 command
            base64_content=$(base64 -w 0 < "$file_path" 2>/dev/null || base64 < "$file_path" | tr -d '\n')
        else
            echo "Error: base64 command not found"
            exit 1
        fi
        
        # Create temporary file for the new asset JSON
        local temp_asset_file=$(mktemp)
        
        # Write the asset JSON to temporary file using jq to ensure proper escaping
        jq -n \
            --arg category "$category" \
            --arg extension "$extension" \
            --arg bytes "$base64_content" \
            --arg color_mode "$color_mode" \
            '{
                category: $category,
                extension: $extension,
                bytes: $bytes,
                color_mode: $color_mode
            }' > "$temp_asset_file"
        
        # Create temporary file for current assets
        local temp_current_file=$(mktemp)
        echo "$ASSETS" > "$temp_current_file"
        
        # Merge the new asset with existing assets using jq
        local temp_result_file=$(mktemp)
        jq --slurpfile new_asset "$temp_asset_file" '. += $new_asset' "$temp_current_file" > "$temp_result_file"
        
        # Read the result back
        ASSETS=$(cat "$temp_result_file")
        
        # Clean up temporary files
        rm -f "$temp_asset_file" "$temp_current_file" "$temp_result_file"
        
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