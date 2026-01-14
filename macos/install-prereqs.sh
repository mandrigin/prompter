#!/bin/bash
set -e

# Prerequisites installer for Android development
# Supports macOS (Homebrew) and Linux (apt/sdkmanager)

ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
CMDLINE_TOOLS_VERSION="11076708"

echo "=== Prerequisites Installer ==="
echo ""

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

OS=$(detect_os)

if [ "$OS" = "unknown" ]; then
    echo "Error: Unsupported operating system"
    exit 1
fi

echo "Detected OS: $OS"
echo ""

# Install Java JDK 17+
install_java() {
    echo "=== Installing Java JDK 17+ ==="

    if [ "$OS" = "macos" ]; then
        if ! command -v brew &> /dev/null; then
            echo "Error: Homebrew is required. Install from https://brew.sh"
            exit 1
        fi

        if brew list openjdk@17 &> /dev/null; then
            echo "Java 17 already installed via Homebrew"
        else
            brew install openjdk@17
        fi

        # Create symlink for system Java wrappers
        if [ ! -L "/Library/Java/JavaVirtualMachines/openjdk-17.jdk" ]; then
            echo "Creating Java symlink (may require sudo)..."
            sudo ln -sfn "$(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk" "/Library/Java/JavaVirtualMachines/openjdk-17.jdk" || true
        fi

        export JAVA_HOME="$(brew --prefix)/opt/openjdk@17"

    elif [ "$OS" = "linux" ]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y openjdk-17-jdk
            export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
        else
            echo "Error: apt-get not found. Please install Java 17 manually."
            exit 1
        fi
    fi

    echo "Java installation complete"
    java -version 2>&1 | head -1
    echo ""
}

# Install Android SDK command-line tools
install_android_cmdline_tools() {
    echo "=== Installing Android SDK Command-Line Tools ==="

    mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"

    if [ -d "$ANDROID_SDK_ROOT/cmdline-tools/latest" ]; then
        echo "Android command-line tools already installed"
    else
        DOWNLOAD_URL=""
        if [ "$OS" = "macos" ]; then
            DOWNLOAD_URL="https://dl.google.com/android/repository/commandlinetools-mac-${CMDLINE_TOOLS_VERSION}_latest.zip"
        elif [ "$OS" = "linux" ]; then
            DOWNLOAD_URL="https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip"
        fi

        echo "Downloading Android command-line tools..."
        TEMP_ZIP=$(mktemp)
        curl -L -o "$TEMP_ZIP" "$DOWNLOAD_URL"

        echo "Extracting..."
        TEMP_DIR=$(mktemp -d)
        unzip -q "$TEMP_ZIP" -d "$TEMP_DIR"
        mv "$TEMP_DIR/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"

        rm -rf "$TEMP_ZIP" "$TEMP_DIR"
    fi

    export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"
    echo "Command-line tools installation complete"
    echo ""
}

# Install Android platform tools
install_platform_tools() {
    echo "=== Installing Android Platform Tools ==="

    if [ -d "$ANDROID_SDK_ROOT/platform-tools" ]; then
        echo "Platform tools already installed"
    else
        yes | sdkmanager "platform-tools" || true
    fi

    export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"
    echo "Platform tools installation complete"
    echo ""
}

# Accept Android SDK licenses
accept_licenses() {
    echo "=== Accepting Android SDK Licenses ==="
    yes | sdkmanager --licenses || true
    echo "Licenses accepted"
    echo ""
}

# Print environment setup instructions
print_env_setup() {
    echo "=== Environment Setup ==="
    echo ""
    echo "Add the following to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
    echo ""
    echo "  export ANDROID_SDK_ROOT=\"$ANDROID_SDK_ROOT\""
    if [ "$OS" = "macos" ]; then
        echo "  export JAVA_HOME=\"\$(brew --prefix)/opt/openjdk@17\""
    else
        echo "  export JAVA_HOME=\"/usr/lib/jvm/java-17-openjdk-amd64\""
    fi
    echo "  export PATH=\"\$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:\$PATH\""
    echo "  export PATH=\"\$ANDROID_SDK_ROOT/platform-tools:\$PATH\""
    echo ""
}

# Main installation flow
main() {
    install_java
    install_android_cmdline_tools
    install_platform_tools
    accept_licenses
    print_env_setup

    echo "=== Installation Complete ==="
    echo ""
    echo "Installed components:"
    echo "  - Java JDK 17+"
    echo "  - Android SDK command-line tools"
    echo "  - Android platform tools"
    echo "  - SDK licenses accepted"
}

main
