import SwiftUI
import MarkdownUI

struct MainView: View {
    @EnvironmentObject var dataStore: DataStore
    @AppStorage("systemPrompt") private var systemPrompt = defaultSystemPrompt

    @State private var promptText: String = ""
    @State private var showingHistory: Bool = true
    @State private var isGenerating: Bool = false
    @State private var currentHistoryItem: PromptHistory? = nil
    @State private var generationError: String? = nil
    @State private var generationTask: Task<Void, Never>? = nil
    @State private var showingErrorAlert: Bool = false

    private let promptService = PromptService()

    /// The output to display - either from current history item or nothing
    private var displayedOutput: String? {
        currentHistoryItem?.generatedOutput
    }

    var body: some View {
        HSplitView {
            if showingHistory {
                HistorySidebar(
                    history: dataStore.history,
                    onSelect: { item in
                        selectHistoryItem(item)
                    },
                    onDelete: { item in
                        if currentHistoryItem?.id == item.id {
                            currentHistoryItem = nil
                        }
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

                // Global scrollable content area
                ScrollView {
                    VStack(spacing: Theme.spacingL) {
                        // Template picker
                        TemplatePicker(
                            templates: dataStore.sortedTemplates,
                            onSelect: { template in
                                promptText = template.content
                            }
                        )

                        // Prompt input with auto-resize
                        AutoResizingPromptInput(
                            text: $promptText,
                            isGenerating: isGenerating,
                            onSubmit: submitPrompt
                        )

                        // Generated output display
                        if isGenerating {
                            GeneratingView(onCancel: cancelGeneration)
                        } else if let output = displayedOutput {
                            MarkdownOutputView(content: output)
                        }
                    }
                    .padding(Theme.spacingXL)
                }

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

    private func selectHistoryItem(_ item: PromptHistory) {
        // Cancel any ongoing generation
        if isGenerating {
            cancelGeneration()
        }

        // Set the prompt text and current item
        promptText = item.prompt
        currentHistoryItem = item
    }

    private func submitPrompt() {
        let trimmedPrompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }

        // Create new history item and set it as current
        let historyItem = PromptHistory(prompt: trimmedPrompt)
        dataStore.addHistoryItem(historyItem)
        currentHistoryItem = historyItem

        generationError = nil
        isGenerating = true

        let inputPrompt = trimmedPrompt
        let currentSystemPrompt = systemPrompt
        let itemId = historyItem.id
        promptText = ""

        generationTask = Task {
            do {
                let output = try await promptService.generatePrompt(
                    for: inputPrompt,
                    systemPrompt: currentSystemPrompt
                )
                if !Task.isCancelled {
                    await MainActor.run {
                        // Update the history item with the generated output
                        if let item = dataStore.history.first(where: { $0.id == itemId }) {
                            dataStore.updateHistoryItemOutput(item, output: output)
                            // Refresh currentHistoryItem to get the updated version
                            currentHistoryItem = dataStore.history.first(where: { $0.id == itemId })
                        }
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

// MARK: - Auto-Resizing Prompt Input

struct AutoResizingPromptInput: View {
    @Binding var text: String
    var isGenerating: Bool = false
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool
    @State private var textHeight: CGFloat = 60

    private let minHeight: CGFloat = 60
    private let maxHeight: CGFloat = 300
    private let lineHeight: CGFloat = 22

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            // Auto-resizing text input
            ZStack(alignment: .topLeading) {
                // Hidden text for measuring
                Text(text.isEmpty ? " " : text)
                    .font(Theme.bodyFont(14))
                    .lineSpacing(4)
                    .padding(Theme.spacingM)
                    .opacity(0)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: TextHeightKey.self,
                                value: geo.size.height
                            )
                        }
                    )

                // Actual text editor
                TextEditor(text: $text)
                    .font(Theme.bodyFont(14))
                    .foregroundColor(Theme.textPrimary)
                    .lineSpacing(4)
                    .scrollContentBackground(.hidden)
                    .scrollDisabled(true)
                    .padding(Theme.spacingM)
                    .focused($isFocused)
                    .disabled(isGenerating)
            }
            .frame(height: max(minHeight, min(textHeight, maxHeight)))
            .themedInput(isFocused: isFocused)
            .onPreferenceChange(TextHeightKey.self) { height in
                textHeight = height
            }

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

private struct TextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 60
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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

            // Content - MarkdownUI (no scroll - parent handles scrolling)
            Markdown(content)
                .markdownTheme(.royalVelvet)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - Custom Markdown Theme

extension MarkdownUI.Theme {
    static let royalVelvet = MarkdownUI.Theme()
        .text {
            ForegroundColor(Theme.textPrimary)
            FontSize(14)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(13)
            ForegroundColor(Theme.accentLight)
            BackgroundColor(Theme.card)
        }
        .strong {
            FontWeight(.semibold)
        }
        .emphasis {
            FontStyle(.italic)
        }
        .link {
            ForegroundColor(Theme.accent)
        }
        .codeBlock { configuration in
            configuration.label
                .markdownTextStyle {
                    FontFamilyVariant(.monospaced)
                    FontSize(13)
                    ForegroundColor(Theme.textPrimary)
                }
                .padding(Theme.spacingM)
                .background(Theme.card)
                .cornerRadius(Theme.radiusS)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusS)
                        .stroke(Theme.border, lineWidth: 1)
                )
                .markdownMargin(top: 8, bottom: 8)
        }
        .heading1 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(20)
                    ForegroundColor(Theme.textPrimary)
                }
                .markdownMargin(top: 16, bottom: 8)
        }
        .heading2 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(17)
                    ForegroundColor(Theme.textPrimary)
                }
                .markdownMargin(top: 12, bottom: 6)
        }
        .heading3 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(15)
                    ForegroundColor(Theme.textPrimary)
                }
                .markdownMargin(top: 10, bottom: 4)
        }
        .paragraph { configuration in
            configuration.label
                .markdownMargin(top: 0, bottom: 12)
        }
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: 4, bottom: 4)
        }
        .blockquote { configuration in
            configuration.label
                .padding(.leading, Theme.spacingM)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.accent.opacity(0.5))
                        .frame(width: 3)
                }
                .markdownMargin(top: 8, bottom: 8)
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
