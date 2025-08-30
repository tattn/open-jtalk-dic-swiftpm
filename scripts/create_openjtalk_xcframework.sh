#!/bin/bash

set -e

# Configuration
DICT_VERSION="1.11"
DICT_URL="https://jaist.dl.sourceforge.net/project/open-jtalk/Dictionary/open_jtalk_dic-${DICT_VERSION}/open_jtalk_dic_utf_8-${DICT_VERSION}.tar.gz"
DICT_NAME="open_jtalk_dic_utf_8-${DICT_VERSION}"
FRAMEWORK_NAME="OpenJTalkDictionary"
XCFRAMEWORK_NAME="${FRAMEWORK_NAME}.xcframework"
BUNDLE_NAME="${FRAMEWORK_NAME}.bundle"
BUILD_DIR="build"
TEMP_DIR="temp"

# Platform configurations
PLATFORMS=(
    "iPhoneOS:iphoneos:arm64:16.0"
    "iPhoneSimulator:iphonesimulator:arm64:16.0"
    "iPhoneSimulator-x86_64:iphonesimulator:x86_64:16.0"
    "MacOSX:macosx:arm64:13.0"
    "MacOSX-x86_64:macosx:x86_64:13.0"
)

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

# Create standalone resource bundle
create_resource_bundle() {
    local bundle_path="$BUILD_DIR/$BUNDLE_NAME"
    
    echo "📦 Creating standalone Resource Bundle..."
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
    echo "✅ Resource Bundle created: $bundle_path"
    echo "📊 Bundle size: $bundle_size"
    
    # Create bundle archive
    echo "📦 Creating bundle archive..."
    cd "$BUILD_DIR"
    zip -r "${BUNDLE_NAME}.zip" "$BUNDLE_NAME"
    
    # Calculate checksum
    local checksum=$(shasum -a 256 "${BUNDLE_NAME}.zip" | cut -d ' ' -f 1)
    echo "✅ Bundle archive created: ${BUNDLE_NAME}.zip"
    echo "🔐 Bundle SHA256 Checksum: $checksum"
    
    cd - > /dev/null
}

# Create dummy source for framework
create_dummy_source() {
    cat > "$TEMP_DIR/dummy.m" <<EOF
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ${FRAMEWORK_NAME} : NSObject
@property (class, readonly) NSBundle *resourceBundle;
@end

@implementation ${FRAMEWORK_NAME}
+ (NSBundle *)resourceBundle { 
    return [NSBundle bundleForClass:[self class]]; 
}
@end

NS_ASSUME_NONNULL_END
EOF
}

# Create framework header
create_framework_header() {
    local header_path="$1"
    
    cat > "$header_path" <<EOF
//
//  ${FRAMEWORK_NAME}.h
//  ${FRAMEWORK_NAME}
//
//  Open JTalk Dictionary Resources
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT double ${FRAMEWORK_NAME}VersionNumber;
FOUNDATION_EXPORT const unsigned char ${FRAMEWORK_NAME}VersionString[];

@interface ${FRAMEWORK_NAME} : NSObject
@property (class, readonly) NSBundle *resourceBundle;
@end

NS_ASSUME_NONNULL_END
EOF
}

# Create module map
create_module_map() {
    local module_path="$1"
    
    cat > "$module_path" <<EOF
framework module ${FRAMEWORK_NAME} {
    umbrella header "${FRAMEWORK_NAME}.h"
    export *
    module * { export * }
}
EOF
}

# Create Info.plist
create_info_plist() {
    local plist_path="$1"
    local platform="$2"
    local sdk="$3"
    local deployment_target="$4"
    
    # Get SDK and build information
    local sdk_version=$(xcrun -sdk ${sdk} --show-sdk-version)
    local sdk_build=$(xcrun -sdk ${sdk} --show-sdk-build-version)
    local xcode_version=$(xcodebuild -version | grep Xcode | cut -d' ' -f2)
    local xcode_build=$(xcodebuild -version | grep Build | cut -d' ' -f3)
    local build_os=$(sw_vers -buildVersion)
    
    # Platform-specific values
    local platform_name=""
    local supported_platforms=""
    local device_family=""
    local required_capabilities=""
    
    case "$platform" in
        "iPhoneOS")
            platform_name="iphoneos"
            supported_platforms="<string>iPhoneOS</string>"
            device_family="<key>UIDeviceFamily</key>
    <array>
        <integer>1</integer>
        <integer>2</integer>
    </array>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arm64</string>
    </array>"
            ;;
        "iPhoneSimulator"|"iPhoneSimulator-x86_64")
            platform_name="iphonesimulator"
            supported_platforms="<string>iPhoneSimulator</string>"
            device_family="<key>UIDeviceFamily</key>
    <array>
        <integer>1</integer>
        <integer>2</integer>
    </array>"
            ;;
        "MacOSX"|"MacOSX-x86_64")
            platform_name="macosx"
            supported_platforms="<string>MacOSX</string>"
            device_family=""
            ;;
    esac
    
    cat > "$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>BuildMachineOSBuild</key>
    <string>${build_os}</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.github.tattn.OpenJTalkDicSwiftPM</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>${DICT_VERSION}</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        ${supported_platforms}
    </array>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>DTCompiler</key>
    <string>com.apple.compilers.llvm.clang.1_0</string>
    <key>DTPlatformBuild</key>
    <string>${sdk_build}</string>
    <key>DTPlatformName</key>
    <string>${platform_name}</string>
    <key>DTPlatformVersion</key>
    <string>${sdk_version}</string>
    <key>DTSDKBuild</key>
    <string>${sdk_build}</string>
    <key>DTSDKName</key>
    <string>${platform_name}${sdk_version}</string>
    <key>DTXcode</key>
    <string>${xcode_version//./}0</string>
    <key>DTXcodeBuild</key>
    <string>${xcode_build}</string>
    <key>MinimumOSVersion</key>
    <string>${deployment_target}</string>
    ${device_family}
</dict>
</plist>
EOF
    
    # Convert to binary format
    # plutil -convert binary1 "$plist_path"
}

# Copy dictionary resources
copy_dictionary_resources() {
    local resources_dir="$1"
    
    echo "📁 Copying dictionary files to Framework Resources..."
    
    # Copy all dictionary files except COPYING
    for item in "$TEMP_DIR/$DICT_NAME"/*; do
        basename=$(basename "$item")
        if [[ "$basename" != "COPYING" ]]; then
            cp -r "$item" "$resources_dir/"
        fi
    done
}

# Create framework
create_framework() {
    local platform=$1
    local sdk=$2
    local arch=$3
    local deployment_target=$4
    
    local framework_dir="$BUILD_DIR/${platform}/${FRAMEWORK_NAME}.framework"
    
    echo "🔨 Creating framework for ${platform} (${arch})..."
    
    # Create framework structure
    mkdir -p "${framework_dir}"
    mkdir -p "${framework_dir}/Headers"
    mkdir -p "${framework_dir}/Resources"
    mkdir -p "${framework_dir}/Modules"
    
    # Create Info.plist
    create_info_plist "${framework_dir}/Info.plist" "$platform" "$sdk" "$deployment_target"
    
    # Create header
    create_framework_header "${framework_dir}/Headers/${FRAMEWORK_NAME}.h"
    
    # Create module map
    create_module_map "${framework_dir}/Modules/module.modulemap"
    
    # Copy dictionary resources directly to Resources folder
    copy_dictionary_resources "${framework_dir}/Resources"
    
    # Set target triple based on platform
    local target_triple=""
    local extra_flags=""
    local platform_flags=""
    
    case "$platform" in
        "iPhoneOS")
            target_triple="${arch}-apple-ios${deployment_target}"
            extra_flags="-fembed-bitcode"
            platform_flags="-mios-version-min=${deployment_target}"
            ;;
        "iPhoneSimulator"|"iPhoneSimulator-x86_64")
            target_triple="${arch}-apple-ios${deployment_target}-simulator"
            platform_flags="-mios-simulator-version-min=${deployment_target}"
            ;;
        "MacOSX")
            target_triple="arm64-apple-macos${deployment_target}"
            platform_flags="-mmacosx-version-min=${deployment_target}"
            ;;
        "MacOSX-x86_64")
            target_triple="x86_64-apple-macos${deployment_target}"
            platform_flags="-mmacosx-version-min=${deployment_target}"
            ;;
    esac
    
    # Compile executable
    xcrun -sdk ${sdk} clang \
        -target ${target_triple} \
        -arch ${arch} \
        -dynamiclib \
        -isysroot $(xcrun -sdk ${sdk} --show-sdk-path) \
        -install_name @rpath/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME} \
        -Xlinker -rpath -Xlinker @executable_path/Frameworks \
        -Xlinker -rpath -Xlinker @loader_path/Frameworks \
        -Xlinker -compatibility_version -Xlinker 1.0.0 \
        -Xlinker -current_version -Xlinker ${DICT_VERSION}.0 \
        -framework Foundation \
        -fobjc-arc \
        -fmodules \
        ${platform_flags} \
        ${extra_flags} \
        -o "${framework_dir}/${FRAMEWORK_NAME}" \
        "$TEMP_DIR/dummy.m"
}

# Create universal binary for macOS
create_macos_universal_binary() {
    echo "🔀 Creating Universal Binary for macOS..."
    
    # Ensure both architectures exist
    if [[ -f "$BUILD_DIR/MacOSX/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" ]] && \
       [[ -f "$BUILD_DIR/MacOSX-x86_64/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" ]]; then
        
        # Create universal binary
        lipo -create \
            "$BUILD_DIR/MacOSX/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" \
            "$BUILD_DIR/MacOSX-x86_64/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" \
            -output "$BUILD_DIR/MacOSX/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}"
        
        # Remove x86_64 specific folder
        rm -rf "$BUILD_DIR/MacOSX-x86_64"
    fi
}

# Create universal binary for iOS Simulator
create_ios_simulator_universal_binary() {
    echo "🔀 Creating Universal Binary for iOS Simulator..."
    
    # Ensure both architectures exist
    if [[ -f "$BUILD_DIR/iPhoneSimulator/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" ]] && \
       [[ -f "$BUILD_DIR/iPhoneSimulator-x86_64/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" ]]; then
        
        # Create universal binary
        lipo -create \
            "$BUILD_DIR/iPhoneSimulator/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" \
            "$BUILD_DIR/iPhoneSimulator-x86_64/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" \
            -output "$BUILD_DIR/iPhoneSimulator/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}"
        
        # Remove x86_64 specific folder
        rm -rf "$BUILD_DIR/iPhoneSimulator-x86_64"
    fi
}

# Create XCFramework
create_xcframework() {
    echo "📦 Creating XCFramework..."
    
    xcodebuild -create-xcframework \
        -framework "$BUILD_DIR/iPhoneOS/${FRAMEWORK_NAME}.framework" \
        -framework "$BUILD_DIR/iPhoneSimulator/${FRAMEWORK_NAME}.framework" \
        -framework "$BUILD_DIR/MacOSX/${FRAMEWORK_NAME}.framework" \
        -output "$BUILD_DIR/${XCFRAMEWORK_NAME}"
}

# Cleanup temporary files
cleanup() {
    echo "🧹 Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
    rm -rf "$BUILD_DIR/iPhoneOS"
    rm -rf "$BUILD_DIR/iPhoneSimulator"
    rm -rf "$BUILD_DIR/MacOSX"
    
    # Remove standalone bundle directory (keep only the zip)
    rm -rf "$BUILD_DIR/$BUNDLE_NAME"
}

# Main execution
main() {
    setup_directories
    download_dictionary
    
    # Create standalone resource bundle first
    create_resource_bundle
    
    # Create XCFramework
    create_dummy_source
    
    # Create frameworks for each platform
    for platform_config in "${PLATFORMS[@]}"; do
        IFS=':' read -r platform sdk arch deployment_target <<< "$platform_config"
        create_framework "$platform" "$sdk" "$arch" "$deployment_target"
    done
    
    # Create universal binary for iOS Simulator
    create_ios_simulator_universal_binary
    
    # Create universal binary for macOS
    create_macos_universal_binary
    
    # Create XCFramework
    create_xcframework
    
    # Cleanup
    cleanup
    
    echo "✅ Build completed successfully!"
    echo ""
    echo "📦 Created files in $BUILD_DIR/:"
    echo "   - ${XCFRAMEWORK_NAME} (XCFramework with embedded resources)"
    echo "   - ${BUNDLE_NAME}.zip (Standalone resource bundle)"
    echo ""
    echo "📝 To use in your Swift Package:"
    echo "   .binaryTarget(name: \"${FRAMEWORK_NAME}\","
    echo "                 path: \"path/to/${XCFRAMEWORK_NAME}\")"
}

# Execute main function
main