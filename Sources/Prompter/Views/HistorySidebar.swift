import SwiftUI

struct HistorySidebar: View {
    let history: [PromptHistory]
    let onSelect: (PromptHistory) -> Void
    let onDelete: (PromptHistory) -> Void
    let onArchive: (PromptHistory) -> Void
    let onUnarchive: (PromptHistory) -> Void

    @State private var searchText: String = ""
    @State private var showArchived: Bool = false

    // Search searches ALL items (archived and active)
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
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.textTertiary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(8)
            .background(Theme.surface)

            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)

            // History list
            if !searchText.isEmpty {
                // Search mode: show ALL matching items (archived and active)
                if searchResults.isEmpty {
                    emptyState(message: "No results")
                } else {
                    List {
                        ForEach(groupItems(searchResults), id: \.0) { section, items in
                            Section(header: Text(section)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Theme.textTertiary)) {
                                ForEach(items) { item in
                                    HistoryRow(
                                        item: item,
                                        onSelect: onSelect,
                                        onDelete: onDelete,
                                        onArchive: onArchive,
                                        onUnarchive: onUnarchive
                                    )
                                }
                            }
                        }
                    }
                    .listStyle(.sidebar)
                    .scrollContentBackground(.hidden)
                }
            } else if activeHistory.isEmpty && archivedHistory.isEmpty {
                emptyState(message: "No history")
            } else {
                List {
                    // Active items
                    ForEach(groupItems(activeHistory), id: \.0) { section, items in
                        Section(header: Text(section)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.textTertiary)) {
                            ForEach(items) { item in
                                HistoryRow(
                                    item: item,
                                    onSelect: onSelect,
                                    onDelete: onDelete,
                                    onArchive: onArchive,
                                    onUnarchive: onUnarchive
                                )
                            }
                        }
                    }

                    // Archived section
                    if !archivedHistory.isEmpty {
                        Section(header: archivedSectionHeader) {
                            if showArchived {
                                ForEach(archivedHistory) { item in
                                    HistoryRow(
                                        item: item,
                                        onSelect: onSelect,
                                        onDelete: onDelete,
                                        onArchive: onArchive,
                                        onUnarchive: onUnarchive
                                    )
                                }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Theme.sidebarGradient)
    }

    private var archivedSectionHeader: some View {
        HStack {
            Image(systemName: "archivebox")
                .font(.system(size: 9))
            Text("Archived (\(archivedHistory.count))")
                .font(.system(size: 10, weight: .semibold))
            Spacer()
            Button(action: { showArchived.toggle() }) {
                Image(systemName: showArchived ? "chevron.down" : "chevron.right")
                    .font(.system(size: 9))
            }
            .buttonStyle(.plain)
        }
        .foregroundColor(Theme.textTertiary)
    }

    private func emptyState(message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .font(.system(size: 11))
                .foregroundColor(Theme.textTertiary)
            Spacer()
        }
    }
}

struct HistoryRow: View {
    let item: PromptHistory
    let onSelect: (PromptHistory) -> Void
    let onDelete: (PromptHistory) -> Void
    let onArchive: (PromptHistory) -> Void
    let onUnarchive: (PromptHistory) -> Void

    @State private var isHovering = false

    private var modeColor: Color {
        switch item.mode {
        case .primary: return Theme.modePrimary
        case .strict: return Theme.modeStrict
        case .exploratory: return Theme.modeExploratory
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(item.prompt)
                        .font(.system(size: 11))
                        .lineLimit(2)
                        .foregroundColor(Theme.textPrimary)

                    if item.isArchived {
                        Image(systemName: "archivebox")
                            .font(.system(size: 9))
                            .foregroundColor(Theme.textTertiary)
                    }
                }

                HStack(spacing: 4) {
                    Text(item.mode.rawValue)
                        .font(.system(size: 9))
                        .foregroundColor(modeColor)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(modeColor.opacity(0.2))
                        .cornerRadius(2)

                    Text(formatDate(item.timestamp))
                        .font(.system(size: 9))
                        .foregroundColor(Theme.textTertiary)
                }
            }

            Spacer()

            if isHovering {
                Button(action: { onDelete(item) }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
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
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

