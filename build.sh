#!/bin/bash
#
# build.sh
# SnapSort
#
# Created by CursorAI on $(date +"%Y-%m-%d").
#

set -e # Stop script execution on error

# Function: Clean up previous build artifacts and intermediate files
cleanup_previous_build() {
    echo "🧹 Cleaning up previous build artifacts and intermediate files..."

    # Clean build directory
    if [ -d "./build" ]; then
        echo "  - Removing build directory contents"
        rm -rf ./build/*
    else
        mkdir -p ./build
    fi

    # Clean potential temporary files
    echo "  - Removing temporary files"
    rm -f exportOptions.plist
    rm -f ./build/*.dmg
    rm -f ./build/*.app
    rm -f ./build/*.json
    rm -f ./build/*.xcarchive

    # Clean potential leftover temporary directories
    echo "  - Removing temporary directories"
    find /tmp -type d -name "tmp.*" -user $(whoami) -mtime +1 -exec rm -rf {} \; 2>/dev/null || true

    echo "✨ Cleanup complete, ready to start new build"
    echo "------------------------------------------------"
}

# Create environment variables example file (if it doesn't exist)
if [ ! -f .env.example ]; then
    echo "📝 Creating .env.example file..."
    cat >.env.example <<EOL
# Apple notarization credentials
# Replace the following values with your own

# Apple ID (your Apple developer account email)
APPLE_ID=your.email@example.com

# App-specific password (generated in Apple ID account settings)
APPLE_PASSWORD=app-specific-password

# Developer Team ID (found in your developer account)
TEAM_ID=XXXXXXXXXX
EOL
fi

# Load environment variables
if [ -f .env ]; then
    echo "🔑 Loading .env file..."
    source .env
else
    echo "❌ Error: .env file does not exist"
    echo "Please create a .env file based on .env.example and add necessary notarization credentials"
    cp -n .env.example .env 2>/dev/null || :
    echo "A .env file template has been created for you, please edit this file and add your credentials"
    exit 1
fi

# Check required environment variables
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_PASSWORD" ] || [ -z "$TEAM_ID" ]; then
    echo "❌ Error: Environment variables are not fully set"
    echo "Please ensure the .env file contains APPLE_ID, APPLE_PASSWORD, and TEAM_ID"
    exit 1
fi

# Configure variables
PROJECT_NAME="SnapSort"
SCHEME_NAME="SnapSort"
APP_NAME="SnapSort"
ARCHIVE_PATH="./build/$APP_NAME.xcarchive"
APP_PATH="./build/$APP_NAME.app"
NOTARIZATION_INFO="./build/notarization-info.json"
NOTARIZATION_LOG="./build/notarization-log.json"

# Print configuration
echo "🛠️  Configuration:"
echo "  - Project: $PROJECT_NAME"
echo "  - Scheme: $SCHEME_NAME"
echo "  - App Name: $APP_NAME"

# Clean previous build
cleanup_previous_build

# Clean previous build artifacts
echo "🧼 Executing xcodebuild clean..."
xcodebuild clean -project "$PROJECT_NAME.xcodeproj" -scheme "$SCHEME_NAME" -configuration Release

# Build application
echo "🏗️  Building application... (grab a coffee ☕ this might take a while)"
xcodebuild archive -project "$PROJECT_NAME.xcodeproj" -scheme "$SCHEME_NAME" -configuration Release -archivePath "$ARCHIVE_PATH"
echo "✅ Build completed successfully!"

# Generate temporary exportOptions.plist (using environment variables)
echo "📄 Generating exportOptions.plist..."
cat >exportOptions.plist <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>signingCertificate</key>
    <string>Developer ID Application</string>
</dict>
</plist>
EOL

# Export application
echo "📦 Exporting application..."
xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" -exportOptionsPlist exportOptions.plist -exportPath "./build"
echo "🚀 Export completed!"

# Read version numbers
VERSION=$(defaults read "$(pwd)/build/$APP_NAME.app/Contents/Info" CFBundleShortVersionString)
BUILD=$(defaults read "$(pwd)/build/$APP_NAME.app/Contents/Info" CFBundleVersion)
DMG_PATH="./build/$APP_NAME-$VERSION.dmg"

echo "🎯 === Starting build for $APP_NAME v$VERSION (build $BUILD) ==="

# Check if create-dmg is installed
if ! command -v create-dmg &>/dev/null; then
    echo "❌ Error: create-dmg command not found"
    echo "Please install it using 'brew install create-dmg'"
    exit 1
fi

# Use direct hdiutil method (more reliable)
echo "💿 Creating DMG file using hdiutil..."
# Create a temporary directory
TMP_DIR=$(mktemp -d)
echo "📁 Creating temporary directory: $TMP_DIR"
# Copy application to temporary directory
echo "📋 Copying application to temporary directory..."
cp -R "$APP_PATH" "$TMP_DIR/"
# Create symbolic link to Applications folder
# First check if link already exists and remove it if it does
if [ -e "$TMP_DIR/Applications" ]; then
    echo "🔄 Removing existing Applications link"
    rm -f "$TMP_DIR/Applications"
fi
echo "🔗 Creating symbolic link to Applications"
ln -s /Applications "$TMP_DIR/Applications"
# Create DMG
echo "🔨 Creating DMG file... 🍺"
hdiutil create -volname "$APP_NAME" -srcfolder "$TMP_DIR" -ov -format UDZO "$DMG_PATH"
echo "✅ DMG file created successfully!"
# Clean up temporary directory
echo "🧹 Cleaning up temporary directory"
rm -rf "$TMP_DIR"

# Sign DMG
echo "🔏 Signing DMG file..."
codesign --force --sign "Developer ID Application: Hangzhou Quest Technology Co., Ltd. (YSM8K853CQ)" "$DMG_PATH"
echo "✅ DMG file signed successfully!"

# Notarize DMG
echo "📤 Submitting notarization request... (time for another coffee ☕)"
NOTARIZATION_OUTPUT=$(mktemp)
echo "📝 Creating notarization output temporary file: $NOTARIZATION_OUTPUT"

xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_PASSWORD" \
    --team-id "$TEAM_ID" \
    --output-format json >"$NOTARIZATION_OUTPUT"

# Extract submission ID using a more robust method to parse JSON
SUBMISSION_ID=$(grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' "$NOTARIZATION_OUTPUT" | head -1 | sed 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

if [ -z "$SUBMISSION_ID" ]; then
    echo "❌ Error: Failed to submit notarization request, unable to get submission ID"
    echo "Notarization output:"
    cat "$NOTARIZATION_OUTPUT"
    echo "🧹 Cleaning up notarization output temporary file"
    rm -f "$NOTARIZATION_OUTPUT"
    exit 1
fi

echo "📋 Notarization request submitted, ID: $SUBMISSION_ID"
echo "⏳ Waiting for notarization to complete... (maybe grab a beer now? 🍺)"
echo "🧹 Cleaning up notarization output temporary file"
rm -f "$NOTARIZATION_OUTPUT"

# Monitor notarization progress
status="in-progress"
progress=0
attempt=0
max_attempts=60 # Maximum 60 attempts (approximately 30 minutes)

while [ "$status" = "in-progress" ] && [ $attempt -lt $max_attempts ]; do
    attempt=$((attempt + 1))
    sleep 30 # Check status every 30 seconds

    # Get notarization status
    xcrun notarytool info "$SUBMISSION_ID" \
        --apple-id "$APPLE_ID" \
        --password "$APPLE_PASSWORD" \
        --team-id "$TEAM_ID" \
        --output-format json >"$NOTARIZATION_INFO"

    status=$(grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' "$NOTARIZATION_INFO" | head -1 | sed 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    new_progress=$(grep -o '"progress"[[:space:]]*:[[:space:]]*[0-9]*' "$NOTARIZATION_INFO" | head -1 | sed 's/.*"progress"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/')

    # Update progress if found
    if [ ! -z "$new_progress" ]; then
        progress=$new_progress
    fi

    # Show a progress bar with emojis
    progress_bar=""
    progress_percent=$((progress * 100 / 100))
    bar_length=20
    completed=$((progress_percent * bar_length / 100))
    remaining=$((bar_length - completed))

    for ((i = 0; i < completed; i++)); do
        progress_bar+="🍺"
    done

    for ((i = 0; i < remaining; i++)); do
        progress_bar+="⬜"
    done

    echo "🔄 Notarization progress: $progress_bar $progress_percent% - Status: $status (Attempt $attempt/$max_attempts)"
done

if [ $attempt -ge $max_attempts ]; then
    echo "❌ Error: Notarization timeout, please check status later using the following command:"
    echo "xcrun notarytool info $SUBMISSION_ID --apple-id \$APPLE_ID --password \$APPLE_PASSWORD --team-id \$TEAM_ID"
    exit 1
fi

# Get detailed notarization log
echo "📋 Getting detailed notarization log..."
xcrun notarytool log "$SUBMISSION_ID" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_PASSWORD" \
    --team-id "$TEAM_ID" \
    --output-format json >"$NOTARIZATION_LOG"

# Check notarization status
if [ "$status" == "Accepted" ]; then
    echo "🎉 Notarization successful! ✅"

    # Add notarization ticket to DMG
    echo "🎟️  Adding notarization ticket to DMG..."
    xcrun stapler staple "$DMG_PATH"
    echo "✅ Stapling completed!"

    echo "🎆 === Build complete! Time to celebrate! 🍻🎊 ==="
    echo "📦 DMG file location: $DMG_PATH"
else
    echo "❌ Notarization failed, status: $status"
    echo "⚠️  Detailed error information:"

    # Extract and display detailed error information
    if [ -f "$NOTARIZATION_LOG" ]; then
        cat "$NOTARIZATION_LOG" | grep -A 5 "issues"

        # Show all detailed log paths for user review
        echo ""
        echo "📝 Complete notarization log located at: $NOTARIZATION_LOG"
    else
        echo "❓ Unable to retrieve detailed error information"
    fi

    echo ""
    echo "📄 Notarization info file: $NOTARIZATION_INFO"
    exit 1
fi

# Clean up temporary files
echo "🧹 Cleaning up final temporary files"
rm -f exportOptions.plist

echo "🏁 Script execution completed successfully! 🎉"
