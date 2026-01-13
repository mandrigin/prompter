import SwiftUI

struct MainView: View {
    @EnvironmentObject var dataStore: DataStore

    @State private var promptText: String = ""
    @State private var selectedMode: PromptMode = .primary
    @State private var showingHistory: Bool = true
    @State private var isGenerating: Bool = false
    @State private var generatedVariants: PromptVariants? = nil
    @State private var generationError: String? = nil

    private let promptService = PromptService()

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
                        isGenerating: isGenerating,
                        onSubmit: submitPrompt
                    )

                    // Generated variants display
                    if isGenerating {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Generating variants...")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else if let error = generationError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else if let variants = generatedVariants {
                        VariantsView(variants: variants, selectedMode: $selectedMode)
                    }
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
        let trimmedPrompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }

        let historyItem = PromptHistory(prompt: trimmedPrompt, mode: selectedMode)
        dataStore.addHistoryItem(historyItem)

        // Clear previous results and start generation
        generatedVariants = nil
        generationError = nil
        isGenerating = true

        let inputPrompt = trimmedPrompt
        promptText = ""

        Task {
            do {
                let variants = try await promptService.generateVariants(for: inputPrompt)
                await MainActor.run {
                    generatedVariants = variants
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    generationError = error.localizedDescription
                    isGenerating = false
                }
            }
        }
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
    var isGenerating: Bool = false
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
                .disabled(isGenerating)

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
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)
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

struct VariantsView: View {
    let variants: PromptVariants
    @Binding var selectedMode: PromptMode

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generated Variants")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)

            ScrollView {
                VStack(spacing: 10) {
                    VariantCard(
                        title: "Primary",
                        content: variants.primary,
                        isSelected: selectedMode == .primary,
                        color: .blue,
                        onSelect: { selectedMode = .primary }
                    )

                    VariantCard(
                        title: "Strict",
                        content: variants.strict,
                        isSelected: selectedMode == .strict,
                        color: .orange,
                        onSelect: { selectedMode = .strict }
                    )

                    VariantCard(
                        title: "Exploratory",
                        content: variants.exploratory,
                        isSelected: selectedMode == .exploratory,
                        color: .purple,
                        onSelect: { selectedMode = .exploratory }
                    )
                }
            }
            .frame(maxHeight: 300)
        }
    }
}

struct VariantCard: View {
    let title: String
    let content: String
    let isSelected: Bool
    let color: Color
    let onSelect: () -> Void

    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(color)

                Spacer()

                Button(action: copyToClipboard) {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard")
            }

            Text(content)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? color.opacity(0.1) : Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? color : Color(NSColor.separatorColor), lineWidth: isSelected ? 2 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCopied = false
        }
    }
}
