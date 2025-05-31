# #!/bin/bash

# set -e

# # Check if we should process branding assets
# if [ "$1" != "true" ]; then
#     echo "Managed login branding is disabled, skipping asset processing"
#     exit 0
# fi

# WORKSPACE_PATH="$2"
# OUTPUT_FILE="$WORKSPACE_PATH/.branding_assets.json"

# echo "Processing branding assets from workspace: $WORKSPACE_PATH"

# # Ensure Python is available
# if ! command -v python3 >/dev/null 2>&1; then
#     echo "Error: python3 is required but not installed"
#     exit 1
# fi

# # Create Python script to handle JSON construction
# PYTHON_SCRIPT=$(cat << 'EOF'
# import json
# import base64
# import sys
# import os

# def add_asset_to_file(output_file, category, extension, file_path, color_mode):
#     """Add a single asset to the JSON file"""
#     try:
#         # Read and encode the image file
#         with open(file_path, 'rb') as f:
#             image_data = f.read()
#             base64_content = base64.b64encode(image_data).decode('utf-8')
        
#         # Create asset object
#         asset = {
#             "category": category,
#             "extension": extension,
#             "bytes": base64_content,
#             "color_mode": color_mode
#         }
        
#         # Read existing assets or start with empty list
#         assets = []
#         if os.path.exists(output_file):
#             try:
#                 with open(output_file, 'r') as f:
#                     content = f.read().strip()
#                     if content:
#                         assets = json.loads(content)
#             except (json.JSONDecodeError, FileNotFoundError):
#                 assets = []
        
#         # Add new asset
#         assets.append(asset)
        
#         # Write back to file
#         with open(output_file, 'w') as f:
#             json.dump(assets, f, indent=2)
        
#         return True
        
#     except Exception as e:
#         print(f"Error processing {file_path}: {e}", file=sys.stderr)
#         return False

# if __name__ == "__main__":
#     if len(sys.argv) != 6:
#         print("Usage: python3 script.py <output_file> <category> <extension> <file_path> <color_mode>", file=sys.stderr)
#         sys.exit(1)
    
#     output_file, category, extension, file_path, color_mode = sys.argv[1:6]
    
#     if add_asset_to_file(output_file, category, extension, file_path, color_mode):
#         print(f"Successfully added {category} asset from {os.path.basename(file_path)}")
#         sys.exit(0)
#     else:
#         sys.exit(1)
# EOF
# )

# # Save Python script to temporary file
# TEMP_PYTHON_SCRIPT="/tmp/process_asset.py"
# echo "$PYTHON_SCRIPT" > "$TEMP_PYTHON_SCRIPT"

# # Initialize empty JSON file
# echo "[]" > "$OUTPUT_FILE"

# # Function to add asset using Python
# add_asset() {
#     local category="$1"
#     local extension="$2"
#     local file_path="$3"
#     local color_mode="$4"
    
#     if [ -f "$file_path" ]; then
#         echo "Processing $file_path for category $category"
        
#         # Use Python to add the asset
#         if python3 "$TEMP_PYTHON_SCRIPT" "$OUTPUT_FILE" "$category" "$extension" "$file_path" "$color_mode"; then
#             echo "Added $category asset"
#         else
#             echo "Failed to add $category asset"
#         fi
#     else
#         echo "Warning: $file_path not found, skipping $category asset"
#     fi
# }

# # Function to process images in a directory
# process_directory() {
#     local dir_path="$1"
#     local category="$2"
#     local color_mode="$3"
    
#     if [ ! -d "$dir_path" ]; then
#         echo "Directory $dir_path not found, skipping $category assets"
#         return
#     fi
    
#     echo "Scanning directory: $dir_path"
    
#     # Find all image files in the directory
#     find "$dir_path" -maxdepth 1 -type f \( \
#         -iname "*.png" -o \
#         -iname "*.jpg" -o \
#         -iname "*.jpeg" -o \
#         -iname "*.ico" -o \
#         -iname "*.svg" \
#     \) | while read -r file_path; do
#         if [ -f "$file_path" ]; then
#             # Get file extension and convert to uppercase
#             extension=$(basename "$file_path" | sed 's/.*\.//' | tr '[:lower:]' '[:upper:]')
            
#             # Handle JPEG files - AWS expects "JPG" not "JPEG"
#             if [ "$extension" = "JPEG" ]; then
#                 extension="JPG"
#             fi
            
#             echo "Found image: $(basename "$file_path") with extension: $extension"
#             add_asset "$category" "$extension" "$file_path" "$color_mode"
#         fi
#     done
# }

# # Process assets from different directories
# echo "Searching for branding assets in standard directories..."

# # Process background images
# process_directory "$WORKSPACE_PATH/assets/background" "PAGE_BACKGROUND" "LIGHT"

# # Process favicon images  
# process_directory "$WORKSPACE_PATH/assets/favicon" "FAVICON_ICO" "LIGHT"

# # Process logo images
# process_directory "$WORKSPACE_PATH/assets/logo" "FORM_LOGO" "LIGHT"

# # Clean up temporary Python script
# rm -f "$TEMP_PYTHON_SCRIPT"

# # Count and display results
# if [ -f "$OUTPUT_FILE" ]; then
#     ASSET_COUNT=$(python3 -c "import json; print(len(json.load(open('$OUTPUT_FILE'))))")
#     echo "Branding assets processed and saved to $OUTPUT_FILE"
#     echo "Generated $ASSET_COUNT assets"
# else
#     echo "No output file created"
# fi 