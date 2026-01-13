import SwiftUI

struct MainView: View {
    @EnvironmentObject var dataStore: DataStore
    @AppStorage("systemPrompt") private var systemPrompt = defaultSystemPrompt

    @State private var promptText: String = ""
    @State private var showingHistory: Bool = true
    @State private var activeRequests: [GenerationRequest] = []
    @State private var generationTasks: [UUID: Task<Void, Never>] = [:]
    @State private var selectedRequestId: UUID? = nil
    @State private var showingErrorAlert: Bool = false
    @State private var errorMessage: String? = nil

    private let promptService = PromptService()

    // Currently selected request (if any)
    private var selectedRequest: GenerationRequest? {
        guard let id = selectedRequestId else { return nil }
        return activeRequests.first { $0.id == id }
    }

    // Check if any request is currently generating
    private var hasActiveGeneration: Bool {
        activeRequests.contains { $0.status == .generating || $0.status == .pending }
    }

    var body: some View {
        HSplitView {
            if showingHistory {
                HistorySidebar(
                    history: dataStore.history,
                    activeRequestIds: Set(activeRequests.map { $0.id }),
                    onSelect: { item in
                        // If there's an active request for this item, select it to resume viewing
                        if activeRequests.contains(where: { $0.id == item.id }) {
                            selectedRequestId = item.id
                        } else {
                            promptText = item.prompt
                        }
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

                    // Prompt input - always enabled
                    PromptInputField(
                        text: $promptText,
                        isGenerating: false,
                        onSubmit: submitPrompt
                    )

                    // Active requests indicator
                    if !activeRequests.isEmpty {
                        ActiveRequestsBar(
                            requests: activeRequests,
                            selectedId: selectedRequestId,
                            onSelect: { id in
                                selectedRequestId = id
                            },
                            onCancel: cancelRequest
                        )
                    }

                    // Output display area - fills remaining space
                    if let request = selectedRequest {
                        RequestOutputView(
                            request: request,
                            onCancel: { cancelRequest(id: request.id) }
                        )
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
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func submitPrompt() {
        let trimmedPrompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }

        // Create history item with generating status
        let historyItem = PromptHistory(prompt: trimmedPrompt, generationStatus: .generating)
        dataStore.addHistoryItem(historyItem)

        // Create generation request
        var request = GenerationRequest(
            id: historyItem.id,
            inputPrompt: trimmedPrompt,
            systemPrompt: systemPrompt
        )
        request.status = .generating

        activeRequests.insert(request, at: 0)
        selectedRequestId = request.id
        promptText = ""

        // Start generation task
        let requestId = request.id
        let inputPrompt = request.inputPrompt
        let currentSystemPrompt = request.systemPrompt

        let task = Task {
            do {
                let output = try await promptService.generatePrompt(
                    for: inputPrompt,
                    systemPrompt: currentSystemPrompt
                )
                if !Task.isCancelled {
                    await MainActor.run {
                        updateRequest(id: requestId, status: .completed, output: output)
                        dataStore.updateHistoryOutput(id: requestId, output: output)
                        dataStore.updateHistoryStatus(id: requestId, status: .completed)
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        updateRequest(id: requestId, status: .failed, error: error.localizedDescription)
                        dataStore.updateHistoryStatus(id: requestId, status: .failed, error: error.localizedDescription)
                    }
                }
            }
            _ = await MainActor.run {
                generationTasks.removeValue(forKey: requestId)
            }
        }

        generationTasks[requestId] = task
    }

    private func updateRequest(id: UUID, status: GenerationStatus, output: String? = nil, error: String? = nil) {
        if let index = activeRequests.firstIndex(where: { $0.id == id }) {
            activeRequests[index].status = status
            if let output = output {
                activeRequests[index].output = output
            }
            if let error = error {
                activeRequests[index].error = error
            }
        }
    }

    private func cancelRequest(id: UUID) {
        generationTasks[id]?.cancel()
        generationTasks.removeValue(forKey: id)
        updateRequest(id: id, status: .cancelled)
        dataStore.updateHistoryStatus(id: id, status: .cancelled)
    }
}

// MARK: - Active Requests Bar

struct ActiveRequestsBar: View {
    let requests: [GenerationRequest]
    let selectedId: UUID?
    let onSelect: (UUID) -> Void
    let onCancel: (UUID) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingS) {
                ForEach(requests) { request in
                    RequestChip(
                        request: request,
                        isSelected: request.id == selectedId,
                        onSelect: { onSelect(request.id) },
                        onCancel: { onCancel(request.id) }
                    )
                }
            }
        }
    }
}

struct RequestChip: View {
    let request: GenerationRequest
    let isSelected: Bool
    let onSelect: () -> Void
    let onCancel: () -> Void

    @State private var isHovered = false

    private var statusColor: Color {
        switch request.status {
        case .pending, .generating:
            return Theme.accent
        case .completed:
            return Theme.success
        case .failed:
            return Theme.error
        case .cancelled:
            return Theme.textTertiary
        }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Theme.spacingXS) {
                // Status indicator
                Group {
                    if request.status == .generating || request.status == .pending {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(Theme.accent)
                    } else {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                    }
                }

                Text(request.promptPreview)
                    .font(Theme.captionFont())
                    .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)
                    .lineLimit(1)

                // Cancel button for active requests
                if request.status == .generating || request.status == .pending {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusS)
                    .fill(isSelected ? Theme.elevated : Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusS)
                    .stroke(isSelected ? Theme.accent.opacity(0.6) : Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Request Output View

struct RequestOutputView: View {
    let request: GenerationRequest
    let onCancel: () -> Void

    var body: some View {
        switch request.status {
        case .pending, .generating:
            GeneratingView(onCancel: onCancel)
        case .completed:
            if let output = request.output {
                MarkdownOutputView(content: output)
            }
        case .failed:
            FailedView(error: request.error ?? "Unknown error")
        case .cancelled:
            CancelledView()
        }
    }
}

struct FailedView: View {
    let error: String

    var body: some View {
        VStack(spacing: Theme.spacingM) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
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
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacingXL)
        .themedCard()
    }
}

struct CancelledView: View {
    var body: some View {
        VStack(spacing: Theme.spacingM) {
            Spacer()

            Image(systemName: "xmark.circle")
                .font(.system(size: 32))
                .foregroundColor(Theme.textTertiary)

            Text("Generation Cancelled")
                .font(Theme.headlineFont())
                .foregroundColor(Theme.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacingXL)
        .themedCard()
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

import MarkdownUI

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

                Button(action: copyAllToClipboard) {
                    HStack(spacing: Theme.spacingXS) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Copied!" : "Copy All")
                    }
                    .font(Theme.captionFont())
                    .foregroundColor(isCopied ? Theme.success : Theme.accent)
                }
                .buttonStyle(.plain)
                .help("Copy entire output to clipboard")
            }

            // Content - MarkdownUI for proper code block rendering
            ScrollView {
                Markdown(content)
                    .markdownTheme(.royalVelvet)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
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

    private func copyAllToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCopied = false
        }
    }
}

// MARK: - Code Block with Copy Button

struct CopyableCodeBlock: View {
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
            CopyableCodeBlock(configuration: configuration)
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
