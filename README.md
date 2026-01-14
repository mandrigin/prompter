# Prompter

A cross-platform prompt engineering app for Claude Code integration.

## Platforms

| Platform | Directory | Status |
|----------|-----------|--------|
| macOS | [`macos/`](macos/) | Menu bar app |
| Android | [`android/`](android/) | Mobile app |

## Repository Structure

```
.
├── macos/                          # macOS app
│   ├── Package.swift               # Swift Package Manager manifest
│   ├── build.sh                    # Build script for creating app bundle
│   ├── install-prereqs.sh          # Prerequisites installer
│   └── Sources/
│       └── Prompter/
│           ├── PrompterApp.swift   # Main app entry point
│           ├── PromptService.swift # Claude Code CLI integration
│           ├── Models/             # Data models
│           ├── Views/              # SwiftUI views
│           └── Resources/          # App resources
├── android/                        # Android app
│   ├── build.gradle.kts            # Gradle build config
│   ├── build.sh                    # Build script
│   └── app/
│       └── src/main/java/com/prompter/
│           ├── ui/                 # Jetpack Compose UI
│           ├── data/               # Data layer
│           └── db/                 # Room database
├── shared/                         # Shared assets (future)
├── .github/workflows/              # CI/CD
└── README.md
```

## Building

### macOS

Requirements:
- macOS 13.0+
- Xcode 15.0+ or Swift 5.9+

```bash
cd macos

# Using build script (recommended)
./build.sh           # Release build
./build.sh debug     # Debug build

# Or using Swift Package Manager
swift build -c release
```

The built app bundle will be at `macos/.build/Prompter.app`.

### Android

Requirements:
- Java JDK 17+
- Android SDK

```bash
cd android

# Install prerequisites (first time only)
../macos/install-prereqs.sh

# Build
./build.sh                     # Using build script
./gradlew assembleDebug        # Debug build
./gradlew assembleRelease      # Release build
```

APK location: `android/app/build/outputs/apk/debug/app-debug.apk`

## Design

Both platforms share the Nothing OS 4.0 + Teenage Engineering inspired design:

- Pure black backgrounds (#000000)
- Nothing red accent (#D71921)
- Monospace typography
- High contrast text
- Sharp geometric shapes

## Features

- Generate prompt variants using Claude AI
- Template system for common prompt patterns
- History with search and archive
- Custom system prompts
- Multiple AI provider support (OpenAI, Claude)

## License

MIT License - see [LICENSE](LICENSE) for details.
