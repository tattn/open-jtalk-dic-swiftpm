#!/bin/bash

set -e

# Configuration
DICT_VERSION="1.11"
DICT_URL="https://jaist.dl.sourceforge.net/project/open-jtalk/Dictionary/open_jtalk_dic-${DICT_VERSION}/open_jtalk_dic_utf_8-${DICT_VERSION}.tar.gz"
DICT_NAME="open_jtalk_dic_utf_8-${DICT_VERSION}"
BUNDLE_NAME="OpenJTalkDictionary.bundle"
BUILD_DIR="build"
TEMP_DIR="temp"

# Change to script's parent directory
cd "$(dirname "$0")/.."

# Setup directories
setup_directories() {
    echo "🏗️ Setting up directories..."
    rm -rf "$BUILD_DIR" "$TEMP_DIR"
    mkdir -p "$BUILD_DIR" "$TEMP_DIR"
}

# Download and extract dictionary
download_dictionary() {
    echo "⬇️ Downloading Open JTalk dictionary..."
    curl -L -o "$TEMP_DIR/dict.tar.gz" "$DICT_URL"
    
    echo "📦 Extracting dictionary..."
    tar -xzf "$TEMP_DIR/dict.tar.gz" -C "$TEMP_DIR"
}

# Create resource bundle
create_bundle() {
    local bundle_path="$BUILD_DIR/$BUNDLE_NAME"
    
    echo "📦 Creating Resource Bundle..."
    mkdir -p "$bundle_path"
    
    # Copy dictionary files to bundle (excluding COPYING file)
    echo "📁 Copying dictionary files to bundle..."
    for item in "$TEMP_DIR/$DICT_NAME"/*; do
        basename=$(basename "$item")
        if [[ "$basename" != "COPYING" ]]; then
            cp -r "$item" "$bundle_path/"
        fi
    done
    
    # Calculate bundle size
    local bundle_size=$(du -sh "$bundle_path" | cut -f1)
    
    echo "✅ Resource Bundle created successfully: $bundle_path"
    echo "📊 Bundle size: $bundle_size"
}

# Create bundle archive
create_bundle_archive() {
    echo "📦 Creating bundle archive..."
    
    cd "$BUILD_DIR"
    zip -r "${BUNDLE_NAME}.zip" "$BUNDLE_NAME"
    
    # Calculate checksum
    local checksum=$(shasum -a 256 "${BUNDLE_NAME}.zip" | cut -d ' ' -f 1)
    
    echo "✅ Archive created: $BUILD_DIR/${BUNDLE_NAME}.zip"
    echo "🔐 SHA256 Checksum: $checksum"
    
    cd - > /dev/null
}

# Cleanup
cleanup() {
    echo "🧹 Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}

# Main execution
main() {
    setup_directories
    download_dictionary
    create_bundle
    create_bundle_archive
    cleanup
    
    echo ""
    echo "📝 Usage in Swift Package:"
    echo "   .process(\"path/to/$BUNDLE_NAME\")"
}

# Execute main function
main