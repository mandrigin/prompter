# Prompter

A macOS menu bar app for Claude Code integration.

## Requirements

- macOS 13.0+
- Xcode 15.0+ or Swift 5.9+

## Building

### Using the build script (recommended)

```bash
# Release build
./build.sh

# Debug build
./build.sh debug
```

The built app bundle will be at `.build/Prompter.app`.

### Using Swift Package Manager directly

```bash
# Debug build
swift build

# Release build
swift build -c release
```

Note: Building with SPM directly produces an executable, not an app bundle. Use `build.sh` to create a proper `.app` bundle with Info.plist.

### Using xcodebuild

Requires full Xcode installation (not just Command Line Tools):

```bash
# Build directly from the Swift package
xcodebuild -scheme Prompter -configuration Release build

# Or open in Xcode
open Package.swift
```

## Running

```bash
# Run the built app
open .build/Prompter.app

# Or install to Applications
cp -r .build/Prompter.app /Applications/
```

## Architecture

Prompter is an agent app (`LSUIElement=true`) that runs in the menu bar without a Dock icon. It provides quick access to Claude Code functionality.

### Project Structure

```
.
├── Package.swift           # Swift Package Manager manifest
├── Sources/
│   └── Prompter/
│       ├── PrompterApp.swift      # Main app entry point
│       └── Resources/
│           └── Info.plist         # App configuration
├── build.sh                # Build script for creating app bundle
└── README.md
```

## License

MIT License - see [LICENSE](LICENSE) for details.
