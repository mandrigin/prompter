#!/bin/bash

# Build script for Prompter Android app
# Wraps gradlew for common build operations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Download gradle wrapper if not present
if [ ! -f "gradlew" ]; then
    echo "Downloading Gradle wrapper..."
    gradle wrapper --gradle-version 8.5
fi

# Make gradlew executable
chmod +x gradlew

# Default action is assembleDebug
ACTION="${1:-assembleDebug}"

case "$ACTION" in
    build|assembleDebug)
        echo "Building debug APK..."
        ./gradlew assembleDebug
        echo ""
        echo "APK location: app/build/outputs/apk/debug/app-debug.apk"
        ;;
    release|assembleRelease)
        echo "Building release APK..."
        ./gradlew assembleRelease
        echo ""
        echo "APK location: app/build/outputs/apk/release/app-release.apk"
        ;;
    clean)
        echo "Cleaning build..."
        ./gradlew clean
        ;;
    test)
        echo "Running tests..."
        ./gradlew test
        ;;
    lint)
        echo "Running lint..."
        ./gradlew lint
        ;;
    install)
        echo "Installing debug APK to connected device..."
        ./gradlew installDebug
        ;;
    *)
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  build, assembleDebug  - Build debug APK (default)"
        echo "  release               - Build release APK"
        echo "  clean                 - Clean build outputs"
        echo "  test                  - Run unit tests"
        echo "  lint                  - Run lint checks"
        echo "  install               - Install debug APK to device"
        echo ""
        echo "Or pass any Gradle task directly."
        ./gradlew "$@"
        ;;
esac
