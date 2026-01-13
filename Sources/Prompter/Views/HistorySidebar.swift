import SwiftUI

struct HistorySidebar: View {
    let history: [PromptHistory]
    let activeRequestIds: Set<UUID>
    let onSelect: (PromptHistory) -> Void
    let onDelete: (PromptHistory) -> Void
    let onArchive: (PromptHistory) -> Void
    let onUnarchive: (PromptHistory) -> Void
    let onCreate: () -> Void
    let onSelectVersion: (PromptHistory, Int) -> Void

    @State private var searchText: String = ""
    @State private var showArchived: Bool = false

    private var searchResults: [PromptHistory] {
        if searchText.isEmpty {
            return []
        }
        return history.filter { $0.prompt.localizedCaseInsensitiveContains(searchText) }
    }

    private var activeHistory: [PromptHistory] {
        history.filter { !$0.isArchived }
    }

    private var archivedHistory: [PromptHistory] {
        history.filter { $0.isArchived }
    }

    private func groupItems(_ items: [PromptHistory]) -> [(String, [PromptHistory])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { item -> String in
            if calendar.isDateInToday(item.timestamp) {
                return "Today"
            } else if calendar.isDateInYesterday(item.timestamp) {
                return "Yesterday"
            } else if calendar.isDate(item.timestamp, equalTo: Date(), toGranularity: .weekOfYear) {
                return "This Week"
            } else {
                return "Earlier"
            }
        }

        let order = ["Today", "Yesterday", "This Week", "Earlier"]
        return order.compactMap { key in
            grouped[key].map { (key, $0) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // New Prompt button
            Button(action: onCreate) {
                HStack(spacing: Theme.spacingS) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("New Prompt")
                        .font(Theme.headlineFont(13))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacingS)
                .background(
                    RoundedRectangle(cornerRadius: Theme.radiusS)
                        .fill(Theme.accent)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingM)

            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)

            // Search field with Opera-like clean styling
            HStack(spacing: Theme.spacingS) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textTertiary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(Theme.captionFont(12))
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
            .background(Theme.card)

            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)

            // History list
            if !searchText.isEmpty {
                if searchResults.isEmpty {
                    emptyState(message: "No results")
                } else {
                    historyList(groupItems(searchResults))
                }
            } else if activeHistory.isEmpty && archivedHistory.isEmpty {
                emptyState(message: "No history yet")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupItems(activeHistory), id: \.0) { section, items in
                            Section(header: sectionHeader(section)) {
                                ForEach(items) { item in
                                    HistoryRow(
                                        item: item,
                                        isActivelyGenerating: activeRequestIds.contains(item.id),
                                        onSelect: onSelect,
                                        onDelete: onDelete,
                                        onArchive: onArchive,
                                        onUnarchive: onUnarchive,
                                        onSelectVersion: onSelectVersion
                                    )
                                }
                            }
                        }

                        if !archivedHistory.isEmpty {
                            Section(header: archivedSectionHeader) {
                                if showArchived {
                                    ForEach(archivedHistory) { item in
                                        HistoryRow(
                                            item: item,
                                            isActivelyGenerating: activeRequestIds.contains(item.id),
                                            onSelect: onSelect,
                                            onDelete: onDelete,
                                            onArchive: onArchive,
                                            onUnarchive: onUnarchive,
                                            onSelectVersion: onSelectVersion
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, Theme.spacingS)
                }
            }
        }
        .background(Theme.sidebarGradient)
    }

    private func historyList(_ grouped: [(String, [PromptHistory])]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(grouped, id: \.0) { section, items in
                    Section(header: sectionHeader(section)) {
                        ForEach(items) { item in
                            HistoryRow(
                                item: item,
                                isActivelyGenerating: activeRequestIds.contains(item.id),
                                onSelect: onSelect,
                                onDelete: onDelete,
                                onArchive: onArchive,
                                onUnarchive: onUnarchive,
                                onSelectVersion: onSelectVersion
                            )
                        }
                    }
                }
            }
            .padding(.vertical, Theme.spacingS)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(Theme.captionFont(10))
                .fontWeight(.semibold)
                .foregroundColor(Theme.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS)
        .background(Theme.surface.opacity(0.95))
    }

    private var archivedSectionHeader: some View {
        HStack(spacing: Theme.spacingS) {
            Image(systemName: "archivebox")
                .font(.system(size: 10, weight: .medium))
            Text("Archived (\(archivedHistory.count))")
                .font(Theme.captionFont(10))
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
            Image(systemName: showArchived ? "chevron.down" : "chevron.right")
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(Theme.textTertiary)
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS)
        .background(Theme.surface.opacity(0.95))
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { showArchived.toggle() } }
    }

    private func emptyState(message: String) -> some View {
        VStack(spacing: Theme.spacingM) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(Theme.textTertiary.opacity(0.5))
            Text(message)
                .font(Theme.captionFont())
                .foregroundColor(Theme.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - History Row

struct HistoryRow: View {
    let item: PromptHistory
    let isActivelyGenerating: Bool
    let onSelect: (PromptHistory) -> Void
    let onDelete: (PromptHistory) -> Void
    let onArchive: (PromptHistory) -> Void
    let onUnarchive: (PromptHistory) -> Void
    let onSelectVersion: (PromptHistory, Int) -> Void

    @State private var isHovered = false

    private var hasMultipleVersions: Bool {
        item.versions.count > 1
    }

    private var statusColor: Color {
        if isActivelyGenerating {
            return Theme.accent
        }
        switch item.generationStatus {
        case .completed:
            return Theme.success
        case .failed:
            return Theme.error
        case .cancelled:
            return Theme.textTertiary
        case .generating, .pending:
            return Theme.accent
        case .none:
            // Legacy items without status - check if they have output
            return item.hasResult ? Theme.success : Theme.textTertiary
        }
    }

    private var versionSelector: some View {
        HStack(spacing: 2) {
            Button(action: {
                let newIndex = max(0, item.selectedVersionIndex - 1)
                onSelectVersion(item, newIndex)
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(item.selectedVersionIndex > 0 ? Theme.textSecondary : Theme.textTertiary.opacity(0.5))
            }
            .buttonStyle(.plain)
            .disabled(item.selectedVersionIndex <= 0)

            Text("v\(item.selectedVersionIndex + 1)/\(item.versions.count)")
                .font(Theme.captionFont(9))
                .foregroundColor(Theme.textSecondary)
                .monospacedDigit()

            Button(action: {
                let newIndex = min(item.versions.count - 1, item.selectedVersionIndex + 1)
                onSelectVersion(item, newIndex)
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(item.selectedVersionIndex < item.versions.count - 1 ? Theme.textSecondary : Theme.textTertiary.opacity(0.5))
            }
            .buttonStyle(.plain)
            .disabled(item.selectedVersionIndex >= item.versions.count - 1)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.card)
        )
    }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.spacingS) {
            // Status indicator
            Group {
                if isActivelyGenerating {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(Theme.accent)
                } else {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 12, height: 12)
            .padding(.top, 3)

            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                HStack(spacing: Theme.spacingXS) {
                    Text(item.prompt)
                        .font(Theme.captionFont(12))
                        .lineSpacing(2)
                        .lineLimit(2)
                        .foregroundColor(Theme.textPrimary)

                    if item.isArchived {
                        Image(systemName: "archivebox")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Theme.textTertiary)
                    }
                }

                HStack(spacing: Theme.spacingS) {
                    Text(formatDate(item.timestamp))
                        .font(Theme.captionFont(10))
                        .foregroundColor(Theme.textTertiary)

                    if hasMultipleVersions {
                        versionSelector
                    }
                }
            }

            Spacer()

            if isHovered {
                Button(action: { item.isArchived ? onUnarchive(item) : onArchive(item) }) {
                    Image(systemName: item.isArchived ? "tray.and.arrow.up" : "archivebox")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textTertiary)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusS)
                .fill(isHovered ? Theme.elevated.opacity(0.5) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture { onSelect(item) }
        .contextMenu {
            Button(action: { onSelect(item) }) {
                Label("Use Prompt", systemImage: "text.cursor")
            }

            Divider()

            if item.isArchived {
                Button(action: { onUnarchive(item) }) {
                    Label("Unarchive", systemImage: "tray.and.arrow.up")
                }
            } else {
                Button(action: { onArchive(item) }) {
                    Label("Archive", systemImage: "archivebox")
                }
            }

            Divider()

            Button(role: .destructive, action: { onDelete(item) }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
