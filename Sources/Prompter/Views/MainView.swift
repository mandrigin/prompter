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
                .frame(minWidth: 180, maxWidth: 240)
                .transition(.move(edge: .leading))
            }

            VStack(spacing: 0) {
                // Draggable title area
                WindowDragArea()

                // Main content with generous spacing
                VStack(spacing: Theme.spacingL) {
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

                    // Generated output display - fills remaining space
                    if isGenerating {
                        GeneratingView(onCancel: cancelGeneration)
                            .frame(maxHeight: .infinity)
                    } else if let output = generatedPrompt {
                        MarkdownOutputView(content: output)
                            .frame(maxHeight: .infinity)
                    } else {
                        Spacer()
                    }
                }
                .padding(Theme.spacingXL)

                // Bottom toolbar
                BottomToolbar(showingHistory: $showingHistory)
            }
            .background(Theme.backgroundGradient)
        }
        .frame(minWidth: 500, minHeight: 400)
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

// MARK: - Window Drag Area

struct WindowDragArea: View {
    var body: some View {
        WindowDragView()
            .frame(height: 32)
    }
}

struct WindowDragView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = DraggableView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    class DraggableView: NSView {
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)

            let label = NSTextField(labelWithString: "Prompter")
            label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            label.textColor = NSColor(Theme.textTertiary)
            label.alignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)

            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: centerXAnchor),
                label.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}

// MARK: - Template Picker

struct TemplatePicker: View {
    let templates: [CustomTemplate]
    let onSelect: (CustomTemplate) -> Void

    var body: some View {
        if !templates.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.spacingS) {
                    ForEach(templates) { template in
                        TemplateChip(template: template, onSelect: onSelect)
                    }
                }
            }
        }
    }
}

struct TemplateChip: View {
    let template: CustomTemplate
    let onSelect: (CustomTemplate) -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: { onSelect(template) }) {
            Text(template.name)
                .font(Theme.captionFont())
                .foregroundColor(isHovered ? Theme.textPrimary : Theme.textSecondary)
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)
                .background(
                    RoundedRectangle(cornerRadius: Theme.radiusS)
                        .fill(isHovered ? Theme.elevated : Theme.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusS)
                        .stroke(isHovered ? Theme.accent.opacity(0.4) : Theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(template.content)
    }
}

// MARK: - Prompt Input Field

struct PromptInputField: View {
    @Binding var text: String
    var isGenerating: Bool = false
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            // Text input with Things-like clean styling
            TextEditor(text: $text)
                .font(Theme.bodyFont(14))
                .foregroundColor(Theme.textPrimary)
                .lineSpacing(4)
                .frame(minHeight: 100, maxHeight: 180)
                .scrollContentBackground(.hidden)
                .padding(Theme.spacingM)
                .themedInput(isFocused: isFocused)
                .focused($isFocused)
                .disabled(isGenerating)

            // Bottom row with hint and button
            HStack(alignment: .center) {
                Text("Describe what you want to accomplish")
                    .font(Theme.captionFont())
                    .foregroundColor(Theme.textTertiary)

                Spacer()

                Button(action: onSubmit) {
                    HStack(spacing: Theme.spacingS) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .medium))
                        Text("Generate")
                            .font(Theme.headlineFont(13))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.spacingL)
                    .padding(.vertical, Theme.spacingS)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusS)
                            .fill(Theme.accent)
                    )
                    .shadow(color: Theme.accentGlow, radius: 8, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)
                .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating ? 0.5 : 1)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
    }
}

// MARK: - Generating View

struct GeneratingView: View {
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Theme.spacingM) {
            Spacer()

            ProgressView()
                .controlSize(.regular)
                .tint(Theme.accent)

            Text("Generating improved prompt...")
                .font(Theme.bodyFont())
                .foregroundColor(Theme.textSecondary)

            Spacer()

            Button(action: onCancel) {
                Text("Cancel")
                    .font(Theme.captionFont())
                    .foregroundColor(Theme.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacingXL)
        .themedCard()
    }
}

// MARK: - Markdown Output View

struct MarkdownOutputView: View {
    let content: String

    @State private var isCopied = false

    private var attributedContent: AttributedString {
        (try? AttributedString(markdown: content)) ?? AttributedString(content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            // Header
            HStack {
                Text("Generated Prompt")
                    .font(Theme.headlineFont())
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Button(action: copyToClipboard) {
                    HStack(spacing: Theme.spacingXS) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Copied!" : "Copy")
                    }
                    .font(Theme.captionFont())
                    .foregroundColor(isCopied ? Theme.success : Theme.accent)
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard")
            }

            // Content - expands to fill available space
            ScrollView {
                Text(attributedContent)
                    .font(Theme.bodyFont(14))
                    .foregroundColor(Theme.textPrimary)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(Theme.spacingM)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusM)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusM)
                    .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(Theme.spacingL)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusL)
                .fill(Theme.accent.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusL)
                .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
        )
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

// MARK: - Bottom Toolbar

struct BottomToolbar: View {
    @Binding var showingHistory: Bool

    var body: some View {
        HStack(spacing: Theme.spacingL) {
            ToolbarButton(
                icon: showingHistory ? "sidebar.left" : "sidebar.leading",
                help: showingHistory ? "Hide history" : "Show history"
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingHistory.toggle()
                }
            }

            Spacer()

            SettingsLink {
                Image(systemName: "gear")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Settings")

            ToolbarButton(icon: "power", help: "Quit Prompter") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.horizontal, Theme.spacingL)
        .padding(.vertical, Theme.spacingM)
        .background(Theme.surface)
    }
}

struct ToolbarButton: View {
    let icon: String
    let help: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isHovered ? Theme.textPrimary : Theme.textSecondary)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(help)
    }
}
