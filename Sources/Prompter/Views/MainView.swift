import SwiftUI

struct MainView: View {
    @EnvironmentObject var dataStore: DataStore

    @State private var promptText: String = ""
    @State private var selectedMode: PromptMode = .primary
    @State private var showingHistory: Bool = true

    var body: some View {
        HSplitView {
            if showingHistory {
                HistorySidebar(
                    history: dataStore.history,
                    onSelect: { item in
                        promptText = item.prompt
                        selectedMode = item.mode
                    },
                    onDelete: { item in
                        dataStore.deleteHistoryItem(item)
                    }
                )
                .frame(minWidth: 150, maxWidth: 200)
            }

            VStack(spacing: 0) {
                // Mode tabs
                ModeTabBar(selectedMode: $selectedMode)

                Divider()

                // Main content
                VStack(spacing: 12) {
                    // Template picker
                    TemplatePicker(
                        templates: dataStore.templatesForMode(selectedMode),
                        onSelect: { template in
                            promptText = template.content
                        }
                    )

                    // Prompt input
                    PromptInputField(
                        text: $promptText,
                        mode: selectedMode,
                        onSubmit: submitPrompt
                    )
                }
                .padding()

                Spacer()

                // Bottom toolbar
                BottomToolbar(showingHistory: $showingHistory)
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }

    private func submitPrompt() {
        guard !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let historyItem = PromptHistory(prompt: promptText, mode: selectedMode)
        dataStore.addHistoryItem(historyItem)

        // TODO: Send to Claude Code CLI
        promptText = ""
    }
}

struct ModeTabBar: View {
    @Binding var selectedMode: PromptMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(PromptMode.allCases, id: \.self) { mode in
                ModeTab(
                    mode: mode,
                    isSelected: selectedMode == mode,
                    action: { selectedMode = mode }
                )
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ModeTab: View {
    let mode: PromptMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mode.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .accentColor : .secondary)

                Rectangle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(height: 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .help(mode.description)
    }
}

struct TemplatePicker: View {
    let templates: [CustomTemplate]
    let onSelect: (CustomTemplate) -> Void

    var body: some View {
        if !templates.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(templates) { template in
                        Button(action: { onSelect(template) }) {
                            Text(template.name)
                                .font(.system(size: 11))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .help(template.content)
                    }
                }
            }
        }
    }
}

struct PromptInputField: View {
    @Binding var text: String
    let mode: PromptMode
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $text)
                .font(.system(size: 13))
                .frame(minHeight: 80, maxHeight: 150)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )

            HStack {
                Text("\(mode.rawValue) mode")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: onSubmit) {
                    HStack(spacing: 4) {
                        Image(systemName: "paperplane.fill")
                        Text("Send")
                    }
                    .font(.system(size: 12))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
    }
}

struct BottomToolbar: View {
    @Binding var showingHistory: Bool

    var body: some View {
        HStack {
            Button(action: { showingHistory.toggle() }) {
                Image(systemName: showingHistory ? "sidebar.left" : "sidebar.leading")
            }
            .buttonStyle(.plain)
            .help(showingHistory ? "Hide history" : "Show history")

            Spacer()

            SettingsLink {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)
            .help("Settings")

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "power")
            }
            .buttonStyle(.plain)
            .help("Quit Prompter")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

