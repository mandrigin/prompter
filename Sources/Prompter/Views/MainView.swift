import SwiftUI
import MarkdownUI

enum PromptLength {
    case short
    case long
}

struct MainView: View {
    @EnvironmentObject var dataStore: DataStore
    @AppStorage("systemPromptShort") private var systemPromptShort = defaultShortSystemPrompt
    @AppStorage("systemPromptLong") private var systemPromptLong = defaultLongSystemPrompt

    @State private var promptText: String = ""
    @State private var showingHistory: Bool = true
    @State private var selectedItemId: UUID? = nil
    @State private var generationTask: Task<Void, Never>? = nil
    @State private var showingErrorAlert: Bool = false
    @State private var errorMessage: String? = nil

    private let promptService = PromptService()

    /// The currently selected history item
    private var selectedItem: PromptHistory? {
        guard let id = selectedItemId else { return nil }
        return dataStore.historyItem(byId: id)
    }

    /// Whether the selected item is currently generating
    private var isSelectedItemGenerating: Bool {
        guard let id = selectedItemId else { return false }
        return dataStore.isGenerating(id: id)
    }

    /// The output to display - either from selected history item or nothing
    private var displayedOutput: String? {
        selectedItem?.generatedOutput
    }

    var body: some View {
        HSplitView {
            if showingHistory {
                HistorySidebar(
                    history: dataStore.history,
                    activeRequestIds: dataStore.generatingItemId.map { Set([$0]) } ?? Set(),
                    selectedItemId: selectedItemId,
                    onSelect: { item in
                        selectHistoryItem(item)
                    },
                    onDelete: { item in
                        if selectedItemId == item.id {
                            selectedItemId = nil
                        }
                        dataStore.deleteHistoryItem(item)
                    },
                    onArchive: { item in
                        dataStore.archiveHistoryItem(item)
                    },
                    onUnarchive: { item in
                        dataStore.unarchiveHistoryItem(item)
                    },
                    onCreate: {
                        createNewPrompt()
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
                            isGenerating: dataStore.generatingItemId != nil,
                            onSubmitShort: { submitPrompt(length: .short) },
                            onSubmitLong: { submitPrompt(length: .long) }
                        )

                        // Generated output display based on selected item state
                        if isSelectedItemGenerating {
                            GeneratingView(onCancel: cancelGeneration)
                        } else if let item = selectedItem {
                            switch item.generationStatus {
                            case .completed:
                                if let output = item.generatedOutput {
                                    MarkdownOutputView(content: output)
                                }
                            case .failed:
                                FailedGenerationView(
                                    error: item.errorMessage ?? "Unknown error",
                                    onRetry: { retryGeneration(item: item) }
                                )
                            case .pending, .cancelled, .none:
                                // Show nothing or a prompt to generate
                                EmptyView()
                            case .generating:
                                // Should not happen if isSelectedItemGenerating is false
                                GeneratingView(onCancel: cancelGeneration)
                            }
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
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func selectHistoryItem(_ item: PromptHistory) {
        // Select the item - don't cancel generation, allow viewing it
        selectedItemId = item.id
        promptText = item.prompt
    }

    private func createNewPrompt() {
        // Create a new empty prompt item and select it
        let newItem = PromptHistory(prompt: "", generationStatus: .pending)
        dataStore.addHistoryItem(newItem)
        selectedItemId = newItem.id
        promptText = ""
    }

    private func submitPrompt(length: PromptLength) {
        let trimmedPrompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }

        let itemId: UUID

        // Check if we have an empty selected item - update it instead of creating new
        if let currentId = selectedItemId,
           let currentItem = dataStore.historyItem(byId: currentId),
           currentItem.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Update the empty prompt with the actual text
            dataStore.updatePromptText(id: currentId, prompt: trimmedPrompt)
            itemId = currentId
        } else if let existingItem = dataStore.findExistingPrompt(trimmedPrompt) {
            // Check if this prompt already exists - if so, add a new version instead of creating duplicate
            itemId = existingItem.id
        } else {
            // Create new history item with generating status
            var historyItem = PromptHistory(prompt: trimmedPrompt)
            historyItem.generationStatus = .generating
            dataStore.addHistoryItem(historyItem)
            itemId = historyItem.id
        }

        selectedItemId = itemId
        let inputPrompt = trimmedPrompt
        let currentSystemPrompt = length == .short ? systemPromptShort : systemPromptLong
        promptText = ""

        // Mark as generating in datastore
        dataStore.startGeneration(id: itemId)

        generationTask = Task {
            do {
                let output = try await promptService.generatePrompt(
                    for: inputPrompt,
                    systemPrompt: currentSystemPrompt
                )
                if !Task.isCancelled {
                    await MainActor.run {
                        dataStore.completeGeneration(id: itemId, output: output)
                        generationTask = nil
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        dataStore.failGeneration(id: itemId, error: error.localizedDescription)
                        errorMessage = error.localizedDescription
                        showingErrorAlert = true
                        generationTask = nil
                    }
                }
            }
        }
    }

    private func retryGeneration(item: PromptHistory) {
        let inputPrompt = item.prompt
        // Default to long system prompt for retries
        let currentSystemPrompt = systemPromptLong
        let itemId = item.id

        // Mark as generating
        dataStore.startGeneration(id: itemId)

        generationTask = Task {
            do {
                let output = try await promptService.generatePrompt(
                    for: inputPrompt,
                    systemPrompt: currentSystemPrompt
                )
                if !Task.isCancelled {
                    await MainActor.run {
                        dataStore.completeGeneration(id: itemId, output: output)
                        generationTask = nil
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        dataStore.failGeneration(id: itemId, error: error.localizedDescription)
                        errorMessage = error.localizedDescription
                        showingErrorAlert = true
                        generationTask = nil
                    }
                }
            }
        }
    }

    private func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        if let id = dataStore.generatingItemId {
            dataStore.cancelGeneration(id: id)
        }
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
                    ForEach(Array(templates.enumerated()), id: \.element.id) { index, template in
                        TemplateChip(template: template, colorIndex: index, onSelect: onSelect)
                    }
                }
            }
        }
    }
}

struct TemplateChip: View {
    let template: CustomTemplate
    let colorIndex: Int
    let onSelect: (CustomTemplate) -> Void

    @State private var isHovered = false

    private var chipColor: (base: Color, highlight: Color) {
        Theme.chipColor(for: colorIndex)
    }

    private var icon: String {
        switch template.name.lowercased() {
        case let name where name.contains("review"):
            return "eye"
        case let name where name.contains("explain"):
            return "lightbulb"
        case let name where name.contains("debug"):
            return "ant"
        case let name where name.contains("fix"):
            return "wrench.and.screwdriver"
        case let name where name.contains("refactor"):
            return "arrow.triangle.2.circlepath"
        case let name where name.contains("architecture"):
            return "building.columns"
        case let name where name.contains("best") || name.contains("practice"):
            return "star"
        case let name where name.contains("test"):
            return "checkmark.seal"
        default:
            return "sparkles"
        }
    }

    var body: some View {
        Button(action: { onSelect(template) }) {
            HStack(spacing: Theme.spacingXS) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(template.name)
                    .font(Theme.captionFont(12))
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
            .background(
                    RoundedRectangle(cornerRadius: Theme.radiusM)
                        .fill(
                            LinearGradient(
                                colors: [chipColor.highlight, chipColor.base],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: chipColor.base.opacity(isHovered ? 0.5 : 0.25),
                            radius: isHovered ? 8 : 4,
                            x: 0,
                            y: isHovered ? 4 : 2
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusM)
                        .stroke(chipColor.highlight.opacity(0.6), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { isHovered = $0 }
        .help(template.content)
    }
}

// MARK: - Auto-Resizing Prompt Input

struct AutoResizingPromptInput: View {
    @Binding var text: String
    var isGenerating: Bool = false
    let onSubmitShort: () -> Void
    let onSubmitLong: () -> Void

    @FocusState private var isFocused: Bool
    @State private var textHeight: CGFloat = 60

    private let minHeight: CGFloat = 60
    private let maxHeight: CGFloat = 200

    private var isDisabled: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            // Auto-resizing text input
            ZStack(alignment: .topLeading) {
                // Hidden text for measuring - must match TextEditor's layout
                Text(text.isEmpty ? " " : text)
                    .font(Theme.bodyFont(14))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
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
                    .scrollDisabled(textHeight <= maxHeight)
                    .padding(Theme.spacingM)
                    .focused($isFocused)
                    .disabled(isGenerating)
            }
            .frame(height: max(minHeight, min(textHeight, maxHeight)))
            .themedInput(isFocused: isFocused)
            .onPreferenceChange(TextHeightKey.self) { height in
                withAnimation(.easeOut(duration: 0.1)) {
                    textHeight = height
                }
            }

            // Bottom row with hint and buttons
            HStack(alignment: .center) {
                Text("Describe what you want to accomplish")
                    .font(Theme.captionFont())
                    .foregroundColor(Theme.textTertiary)

                Spacer()

                HStack(spacing: Theme.spacingS) {
                    // Short prompt button
                    Button(action: onSubmitShort) {
                        HStack(spacing: Theme.spacingXS) {
                            Image(systemName: "bolt")
                                .font(.system(size: 11, weight: .medium))
                            Text("Short")
                                .font(Theme.headlineFont(12))
                        }
                        .foregroundColor(Theme.accent)
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.vertical, Theme.spacingS)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusS)
                                .fill(Theme.accent.opacity(0.15))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusS)
                                .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isDisabled)
                    .opacity(isDisabled ? 0.5 : 1)
                    .keyboardShortcut(.return, modifiers: .command)
                    .help("Generate a concise, focused prompt")

                    // Long prompt button
                    Button(action: onSubmitLong) {
                        HStack(spacing: Theme.spacingXS) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11, weight: .medium))
                            Text("Long")
                                .font(Theme.headlineFont(12))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.vertical, Theme.spacingS)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusS)
                                .fill(Theme.accent)
                        )
                        .shadow(color: Theme.accentGlow, radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(isDisabled)
                    .opacity(isDisabled ? 0.5 : 1)
                    .keyboardShortcut(.return, modifiers: [.command, .shift])
                    .help("Generate a detailed, comprehensive prompt")
                }
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

// MARK: - Failed Generation View

struct FailedGenerationView: View {
    let error: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: Theme.spacingM) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(Theme.error)

            Text("Generation Failed")
                .font(Theme.headlineFont())
                .foregroundColor(Theme.textPrimary)

            Text(error)
                .font(Theme.bodyFont())
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button(action: onRetry) {
                HStack(spacing: Theme.spacingS) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                    Text("Retry")
                        .font(Theme.headlineFont(13))
                }
                .foregroundColor(.white)
                .padding(.horizontal, Theme.spacingL)
                .padding(.vertical, Theme.spacingS)
                .background(
                    RoundedRectangle(cornerRadius: Theme.radiusS)
                        .fill(Theme.accent)
                )
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

// MARK: - Code Block with Copy Button

struct CodeBlockView: View {
    let configuration: CodeBlockConfiguration

    @State private var isCopied = false
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with language and copy button
            HStack {
                if let language = configuration.language {
                    Text(language)
                        .font(Theme.captionFont(10))
                        .foregroundColor(Theme.textTertiary)
                        .textCase(.uppercase)
                }

                Spacer()

                Button(action: copyCode) {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Copied" : "Copy")
                    }
                    .font(Theme.captionFont(10))
                    .foregroundColor(isCopied ? Theme.success : Theme.textSecondary)
                }
                .buttonStyle(.plain)
                .opacity(isHovered || isCopied ? 1 : 0)
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
            .background(Theme.elevated)

            // Code content
            configuration.label
                .markdownTextStyle {
                    FontFamilyVariant(.monospaced)
                    FontSize(13)
                    ForegroundColor(Theme.textPrimary)
                }
                .padding(Theme.spacingM)
        }
        .background(Theme.card)
        .cornerRadius(Theme.radiusS)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusS)
                .stroke(isHovered ? Theme.accent.opacity(0.3) : Theme.border, lineWidth: 1)
        )
        .onHover { isHovered = $0 }
    }

    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(configuration.content, forType: .string)
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
            CodeBlockView(configuration: configuration)
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
