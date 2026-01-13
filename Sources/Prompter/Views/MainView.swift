import SwiftUI

struct MainView: View {
    @EnvironmentObject var dataStore: DataStore
    @AppStorage("systemPrompt") private var systemPrompt = defaultSystemPrompt

    @State private var promptText: String = ""
    @State private var showingHistory: Bool = true
    @State private var isGenerating: Bool = false
    @State private var generatedPrompt: String? = nil
    @State private var generationError: String? = nil
    @State private var generationTask: Task<Void, Never>? = nil
    @State private var showingErrorAlert: Bool = false

    private let promptService = PromptService()

    var body: some View {
        HSplitView {
            if showingHistory {
                HistorySidebar(
                    history: dataStore.history,
                    onSelect: { item in
                        promptText = item.prompt
                    },
                    onDelete: { item in
                        dataStore.deleteHistoryItem(item)
                    },
                    onArchive: { item in
                        dataStore.archiveHistoryItem(item)
                    },
                    onUnarchive: { item in
                        dataStore.unarchiveHistoryItem(item)
                    }
                )
                .frame(minWidth: 150, maxWidth: 200)
                .transition(.move(edge: .leading))
            }

            VStack(spacing: 0) {
                // Main content
                VStack(spacing: 12) {
                    // Template picker
                    TemplatePicker(
                        templates: dataStore.sortedTemplates,
                        onSelect: { template in
                            promptText = template.content
                        }
                    )

                    // Prompt input
                    PromptInputField(
                        text: $promptText,
                        isGenerating: isGenerating,
                        onSubmit: submitPrompt
                    )

                    // Generated output display
                    if isGenerating {
                        GeneratingView(onCancel: cancelGeneration)
                    } else if let output = generatedPrompt {
                        MarkdownOutputView(content: output)
                    }
                }
                .padding()

                Spacer()

                // Bottom toolbar
                BottomToolbar(showingHistory: $showingHistory)
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .alert("Generation Failed", isPresented: $showingErrorAlert) {
            Button("Dismiss", role: .cancel) {
                generationError = nil
            }
        } message: {
            Text(generationError ?? "An unknown error occurred")
        }
    }

    private func submitPrompt() {
        let trimmedPrompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }

        let historyItem = PromptHistory(prompt: trimmedPrompt)
        dataStore.addHistoryItem(historyItem)

        // Clear previous results and start generation
        generatedPrompt = nil
        generationError = nil
        isGenerating = true

        let inputPrompt = trimmedPrompt
        let currentSystemPrompt = systemPrompt
        promptText = ""

        generationTask = Task {
            do {
                let output = try await promptService.generatePrompt(
                    for: inputPrompt,
                    systemPrompt: currentSystemPrompt
                )
                if !Task.isCancelled {
                    await MainActor.run {
                        generatedPrompt = output
                        isGenerating = false
                        generationTask = nil
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        generationError = error.localizedDescription
                        showingErrorAlert = true
                        isGenerating = false
                        generationTask = nil
                    }
                }
            }
        }
    }

    private func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        isGenerating = false
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
                Text("Enter your prompt idea")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: onSubmit) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("Generate")
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

struct GeneratingView: View {
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .controlSize(.regular)
            Text("Generating improved prompt...")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer()

            Button(action: onCancel) {
                Text("Cancel")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

struct MarkdownOutputView: View {
    let content: String

    @State private var isCopied = false

    private var attributedContent: AttributedString {
        (try? AttributedString(markdown: content)) ?? AttributedString(content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Generated Prompt")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Button(action: copyToClipboard) {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Copied!" : "Copy")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(isCopied ? .green : .accentColor)
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard")
            }

            ScrollView {
                Text(attributedContent)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(minHeight: 100, maxHeight: 250)
            .padding(12)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.05))
        .cornerRadius(10)
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

struct BottomToolbar: View {
    @Binding var showingHistory: Bool

    var body: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingHistory.toggle()
                }
            }) {
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
