import SwiftUI

struct HistorySidebar: View {
    let history: [PromptHistory]
    let onSelect: (PromptHistory) -> Void
    let onDelete: (PromptHistory) -> Void

    @State private var searchText: String = ""

    private var filteredHistory: [PromptHistory] {
        if searchText.isEmpty {
            return history
        }
        return history.filter { $0.prompt.localizedCaseInsensitiveContains(searchText) }
    }

    private var groupedHistory: [(String, [PromptHistory])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredHistory) { item -> String in
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
                    .foregroundColor(.secondary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // History list
            if filteredHistory.isEmpty {
                VStack {
                    Spacer()
                    Text("No history")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(groupedHistory, id: \.0) { section, items in
                        Section(header: Text(section).font(.system(size: 10, weight: .semibold))) {
                            ForEach(items) { item in
                                HistoryRow(item: item, onSelect: onSelect, onDelete: onDelete)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct HistoryRow: View {
    let item: PromptHistory
    let onSelect: (PromptHistory) -> Void
    let onDelete: (PromptHistory) -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.prompt)
                    .font(.system(size: 11))
                    .lineLimit(2)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text(item.mode.rawValue)
                        .font(.system(size: 9))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(modeColor.opacity(0.2))
                        .cornerRadius(2)

                    Text(formatDate(item.timestamp))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isHovering {
                Button(action: { onDelete(item) }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture { onSelect(item) }
    }

    private var modeColor: Color {
        switch item.mode {
        case .primary: return .blue
        case .strict: return .orange
        case .exploratory: return .purple
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

