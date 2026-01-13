#!/bin/bash
set -e

# Build configuration
BUILD_DIR=".build"
APP_NAME="Prompter"
BUNDLE_NAME="${APP_NAME}.app"
CONFIGURATION="${1:-release}"

echo "Building Prompter in ${CONFIGURATION} mode..."

# Clean previous build artifacts
rm -rf "${BUILD_DIR}/${BUNDLE_NAME}"

# Build the Swift package
if [ "$CONFIGURATION" = "release" ]; then
    swift build -c release
    EXECUTABLE_PATH="${BUILD_DIR}/release/${APP_NAME}"
else
    swift build
    EXECUTABLE_PATH="${BUILD_DIR}/debug/${APP_NAME}"
fi

# Create the app bundle structure
APP_BUNDLE="${BUILD_DIR}/${BUNDLE_NAME}"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy executable
cp "${EXECUTABLE_PATH}" "${MACOS_DIR}/${APP_NAME}"

# Copy Info.plist
cp "Sources/Prompter/Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"

# Copy any other resources (if they exist)
if [ -d "Sources/Prompter/Resources" ]; then
    find "Sources/Prompter/Resources" -type f ! -name "Info.plist" -exec cp {} "${RESOURCES_DIR}/" \; 2>/dev/null || true
fi

echo "Build complete: ${APP_BUNDLE}"
echo ""
echo "To run the app:"
echo "  open ${APP_BUNDLE}"
echo ""
echo "To install to /Applications:"
echo "  cp -r ${APP_BUNDLE} /Applications/"
