import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    SettingsTabButton(tab: tab, isSelected: selectedTab == tab) {
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

            Divider()
                .padding(.top, 12)

            // Content
            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .api:
                    APISettingsView()
                case .hotkeys:
                    HotkeySettingsView()
                case .templates:
                    TemplateSettingsView()
                }
            }
            .padding()

            Spacer()

            Divider()

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }
}

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case api = "API"
    case hotkeys = "Hotkeys"
    case templates = "Templates"

    var icon: String {
        switch self {
        case .general: return "gear"
        case .api: return "key"
        case .hotkeys: return "keyboard"
        case .templates: return "doc.text"
        }
    }
}

struct SettingsTabButton: View {
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20))
                Text(tab.rawValue)
                    .font(.system(size: 10))
            }
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .frame(width: 70, height: 50)
        }
        .buttonStyle(.plain)
    }
}

/// Default system prompt used for generating improved prompts
let defaultSystemPrompt = """
You are a prompt engineering assistant. Given a user's rough idea or description, \
generate an improved, well-structured prompt.

Format your response in markdown with:
- A clear, actionable prompt
- Key considerations or context if relevant
- Example usage if helpful

Be concise but thorough. Focus on making the prompt effective for AI assistants.
"""

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showDockIcon") private var showDockIcon = false
    @AppStorage("systemPrompt") private var systemPrompt = defaultSystemPrompt

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                Toggle("Show in Dock", isOn: $showDockIcon)
            }

            Section("System Prompt") {
                TextEditor(text: $systemPrompt)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(height: 120)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )

                HStack {
                    Text("Customize the instructions sent to Claude when generating prompts")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Reset to Default") {
                        systemPrompt = defaultSystemPrompt
                    }
                    .controlSize(.small)
                    .disabled(systemPrompt == defaultSystemPrompt)
                }
            }

            Section {
                LabeledContent("Version") {
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct APISettingsView: View {
    @AppStorage("anthropicAPIKey") private var apiKey = ""
    @AppStorage("claudeCodePath") private var claudeCodePath = "/usr/local/bin/claude"
    @State private var showingAPIKey = false

    var body: some View {
        Form {
            Section("Anthropic API") {
                HStack {
                    if showingAPIKey {
                        TextField("API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button(action: { showingAPIKey.toggle() }) {
                        Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                }

                Text("Get your API key from console.anthropic.com")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Section("Claude Code CLI") {
                TextField("Path to claude", text: $claudeCodePath)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Browse...") {
                        browseForClaude()
                    }

                    Button("Detect") {
                        detectClaude()
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private func browseForClaude() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            claudeCodePath = url.path
        }
    }

    private func detectClaude() {
        let possiblePaths = [
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
            "\(NSHomeDirectory())/.local/bin/claude",
        ]

        for path in possiblePaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                claudeCodePath = path
                return
            }
        }
    }
}

struct HotkeySettingsView: View {
    @AppStorage("globalHotkey") private var globalHotkey = "⌘⇧P"
    @AppStorage("sendHotkey") private var sendHotkey = "⌘↩"

    var body: some View {
        Form {
            Section("Global") {
                LabeledContent("Show Prompter") {
                    HotkeyField(hotkey: $globalHotkey)
                }
            }

            Section("In App") {
                LabeledContent("Generate Prompt") {
                    HotkeyField(hotkey: $sendHotkey)
                }
            }

            Section {
                Text("Click on a hotkey field and press your desired key combination")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

struct HotkeyField: View {
    @Binding var hotkey: String
    @State private var isRecording = false

    var body: some View {
        Text(hotkey)
            .font(.system(size: 12, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isRecording ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isRecording ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: 1)
            )
            .onTapGesture {
                isRecording = true
            }
    }
}

struct TemplateSettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedTemplate: CustomTemplate?
    @State private var showingAddTemplate = false

    var body: some View {
        HSplitView {
            // Template list
            List(selection: $selectedTemplate) {
                ForEach(dataStore.sortedTemplates) { template in
                    Text(template.name)
                        .tag(template)
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 150)

            // Template editor
            if let template = selectedTemplate {
                TemplateEditor(
                    template: template,
                    onUpdate: { updated in
                        dataStore.updateTemplate(updated)
                        selectedTemplate = updated
                    },
                    onDelete: {
                        dataStore.deleteTemplate(template)
                        selectedTemplate = nil
                    }
                )
            } else {
                VStack {
                    Text("Select a template to edit")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: { showingAddTemplate = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTemplate) {
            AddTemplateView { name, content in
                let template = CustomTemplate(name: name, content: content, sortOrder: dataStore.templates.count)
                dataStore.addTemplate(template)
            }
        }
    }
}

struct TemplateEditor: View {
    let template: CustomTemplate
    let onUpdate: (CustomTemplate) -> Void
    let onDelete: () -> Void

    @State private var name: String
    @State private var content: String

    init(template: CustomTemplate, onUpdate: @escaping (CustomTemplate) -> Void, onDelete: @escaping () -> Void) {
        self.template = template
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._name = State(initialValue: template.name)
        self._content = State(initialValue: template.content)
    }

    var body: some View {
        Form {
            TextField("Name", text: $name)
                .onChange(of: name) { _, newValue in
                    updateTemplate(name: newValue)
                }

            LabeledContent("Content") {
                TextEditor(text: $content)
                    .frame(height: 100)
                    .onChange(of: content) { _, newValue in
                        updateTemplate(content: newValue)
                    }
            }

            if !template.isDefault {
                Button("Delete Template", role: .destructive, action: onDelete)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func updateTemplate(name: String? = nil, content: String? = nil) {
        var updated = template
        if let name = name { updated.name = name }
        if let content = content { updated.content = content }
        onUpdate(updated)
    }
}

struct AddTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var content = ""

    let onCreate: (String, String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("New Template")
                .font(.headline)

            Form {
                TextField("Name", text: $name)

                LabeledContent("Content") {
                    TextEditor(text: $content)
                        .frame(height: 80)
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    dismiss()
                }

                Spacer()

                Button("Create") {
                    onCreate(name, content)
                    dismiss()
                }
                .disabled(name.isEmpty || content.isEmpty)
            }
        }
        .padding()
        .frame(width: 350, height: 280)
    }
}
