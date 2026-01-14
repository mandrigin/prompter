# Prompter

A macOS menu bar app for Claude Code integration.

## Table of Contents

- [Requirements](#requirements)
- [Building (macOS)](#building-macos)
  - [Using the build script](#using-the-build-script-recommended)
  - [Using Swift Package Manager](#using-swift-package-manager-directly)
  - [Using xcodebuild](#using-xcodebuild)
- [Building (Android)](#building-android)
  - [Prerequisites](#prerequisites)
  - [Build Commands](#build-commands)
  - [APK Location](#apk-location)
- [Running](#running)
- [How to Use](#how-to-use)
  - [Opening Prompter](#opening-prompter)
  - [Entering Prompts](#entering-prompts)
  - [Understanding the Modes](#understanding-the-modes)
  - [Using Templates](#using-templates)
  - [Working with History](#working-with-history)
  - [Archiving Prompts](#archiving-prompts)
  - [Settings](#settings)
  - [Customizing the System Prompt](#customizing-the-system-prompt)
- [Architecture](#architecture)
  - [Project Structure](#project-structure)
  - [Nothing OS 4.0 Design](#nothing-os-40-design)
- [License](#license)

## Requirements

- macOS 13.0+
- Xcode 15.0+ or Swift 5.9+
- Claude Code CLI installed

## Building (macOS)

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

## Building (Android)

### Prerequisites

Install the required development tools using the provided script:

```bash
./install-prereqs.sh
```

This script installs:
- Java JDK 17+
- Android SDK command-line tools
- Android platform tools
- Accepts SDK licenses automatically

**Manual installation** (if you prefer not to use the script):
- Install Java JDK 17 or later
- Install Android Studio or Android SDK command-line tools
- Set `ANDROID_SDK_ROOT` environment variable
- Accept licenses: `sdkmanager --licenses`

### Build Commands

```bash
# Using the build script (recommended)
./build.sh

# Or using Gradle directly
./gradlew assembleDebug    # Debug build
./gradlew assembleRelease  # Release build

# Clean build
./gradlew clean assembleDebug
```

### APK Location

After a successful build, find the APK at:

```
app/build/outputs/apk/debug/app-debug.apk        # Debug build
app/build/outputs/apk/release/app-release.apk    # Release build
```

Install on a connected device:

```bash
adb install app/build/outputs/apk/debug/app-debug.apk
```

## Running

```bash
# Run the built app
open .build/Prompter.app

# Or install to Applications
cp -r .build/Prompter.app /Applications/
```

## How to Use

### Opening Prompter

Prompter lives in your menu bar. Click the **terminal icon** in the menu bar to open the main window.

### Entering Prompts

1. Type your prompt in the text editor area
2. Press **Cmd+Return** or click the **Send** button to submit
3. Prompter sends your input to Claude Code CLI and generates three prompt variants
4. View the generated variants in the output area below

### Understanding the Modes

Prompter generates three variants for each prompt, each with a different style:

| Mode | Description | Use When |
|------|-------------|----------|
| **Primary** | Balanced responses with good context | General-purpose prompting |
| **Strict** | Focused, concise responses | You need minimal, constrained output |
| **Exploratory** | Creative, expansive responses | You want broader ideas and alternatives |

Click the mode tabs at the top of the window to switch between them. The output view updates to show the selected variant.

### Using Templates

Each mode includes pre-defined templates to help you get started:

- **Primary**: Code Review, Explain Code, Debug Help
- **Strict**: Quick Fix, Syntax Check, Refactor
- **Exploratory**: Architecture, Alternatives, Best Practices

Click a template button to populate the prompt field with its content, then customize as needed.

### Working with History

The sidebar shows your prompt history, grouped by date (Today, Yesterday, This Week, Earlier).

- **Click** any past prompt to reload it into the editor
- **Search** using the search field at the top of the sidebar
- **Right-click** for context menu options (Use Prompt, Archive, Delete)
- Use the **sidebar toggle** button in the bottom toolbar to show or hide history

### Archiving Prompts

Keep your history organized by archiving prompts you want to preserve but don't need to see regularly:

- **Archive**: Right-click a prompt and select "Archive" to move it to the Archived section
- **View Archived**: Click the chevron next to "Archived" in the sidebar to expand/collapse
- **Unarchive**: Right-click an archived prompt and select "Unarchive" to restore it
- **Search**: Searches include both active and archived prompts

### Settings

Access settings through:
- **Gear icon** in the bottom toolbar
- **Cmd+,** keyboard shortcut

Click the **power icon** to quit Prompter.

### Customizing the System Prompt

You can customize the instructions sent to Claude when generating prompt variants:

1. Open **Settings** (gear icon or Cmd+,)
2. Go to the **General** tab
3. Edit the **System Prompt** text field

The default system prompt instructs Claude to act as a prompt engineering assistant, generating three variants (primary, strict, exploratory) for your input. You can modify this to change how Claude interprets and transforms your prompts.

Click **Reset to Default** to restore the original system prompt.

## Architecture

Prompter is an agent app (`LSUIElement=true`) that runs in the menu bar without a Dock icon. It provides quick access to Claude Code functionality.

### Project Structure

```
.
├── Package.swift                    # Swift Package Manager manifest
├── build.sh                         # Build script for creating app bundle
├── Sources/
│   └── Prompter/
│       ├── PrompterApp.swift        # Main app entry point
│       ├── PromptService.swift      # Claude Code CLI integration
│       ├── Models/
│       │   ├── DataStore.swift      # App state management
│       │   ├── PromptHistory.swift  # History data model
│       │   └── CustomTemplate.swift # Template data model
│       ├── Views/
│       │   ├── MainView.swift       # Main window UI
│       │   ├── HistorySidebar.swift # History sidebar
│       │   └── SettingsView.swift   # Settings window
│       └── Resources/
│           └── Info.plist           # App configuration
├── app/                             # Android app module
│   └── src/main/java/com/prompter/
│       └── ui/theme/
│           └── NothingTheme.kt      # Nothing OS 4.0 theme
└── README.md
```

### Nothing OS 4.0 Design

The Android version features a Nothing OS 4.0-inspired visual design:

**Color Palette**
- Monochromatic base: Pure black (#000000) and white (#FFFFFF)
- Accent color: Nothing red (#D71921)
- High contrast for accessibility and readability

**Typography**
- Dot-matrix aesthetic inspired by NDot font family
- Monospace typeface for technical, clean appearance
- Consistent weight hierarchy across all text styles

**Visual Elements**
- Clean geometric shapes with subtle rounded corners
- Minimal shadows and depth
- Glyph-style iconography
- Both dark and light theme support

**Implementation**
The theme is implemented in `NothingTheme.kt` using Jetpack Compose Material3:
- `NothingColors` - Color definitions
- `NothingTypography` - Text styles
- `NothingShapes` - Shape definitions
- `NothingTheme()` - Composable theme wrapper

## License

MIT License - see [LICENSE](LICENSE) for details.
