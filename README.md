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

## How to Use

### Opening Prompter

Prompter lives in your menu bar. Click the **terminal icon** in the menu bar to open the main window.

### Entering Prompts

1. Type your prompt in the text editor area
2. Press **Cmd+Return** or click the **Send** button to submit
3. Prompter sends your input to Claude Code CLI and generates three prompt variants

### Understanding the Modes

Prompter offers three modes, each generating a different style of prompt:

| Mode | Description | Use When |
|------|-------------|----------|
| **Primary** | Balanced responses with good context | General-purpose prompting |
| **Strict** | Focused, concise responses | You need minimal, constrained output |
| **Exploratory** | Creative, expansive responses | You want broader ideas and alternatives |

Click the mode tabs at the top of the window to switch between them.

### Using Templates

Each mode includes pre-defined templates to help you get started:

- **Primary**: Code Review, Explain Code, Debug Help
- **Strict**: Quick Fix, Syntax Check, Refactor
- **Exploratory**: Architecture, Alternatives, Best Practices

Click a template button to populate the prompt field with its content, then customize as needed.

### History

The sidebar shows your prompt history. Click any past prompt to reload it into the editor. Use the sidebar toggle button in the bottom toolbar to show or hide history.

### Settings

Click the **gear icon** in the bottom toolbar to access settings. Click the **power icon** to quit Prompter.

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
