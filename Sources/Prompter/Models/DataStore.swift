import Foundation
import SwiftUI

@MainActor
class DataStore: ObservableObject {
    @Published var history: [PromptHistory] = []
    @Published var templates: [CustomTemplate] = []

    private let historyKey = "promptHistory"
    private let templatesKey = "customTemplates"
    private let defaults = UserDefaults.standard

    init() {
        loadHistory()
        loadTemplates()
        seedDefaultTemplatesIfNeeded()
    }

    // MARK: - History Management

    func addHistoryItem(_ item: PromptHistory) {
        history.insert(item, at: 0)
        saveHistory()
    }

    func deleteHistoryItem(_ item: PromptHistory) {
        history.removeAll { $0.id == item.id }
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    private func loadHistory() {
        guard let data = defaults.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([PromptHistory].self, from: data) else {
            return
        }
        history = decoded.sorted { $0.timestamp > $1.timestamp }
    }

    private func saveHistory() {
        guard let encoded = try? JSONEncoder().encode(history) else { return }
        defaults.set(encoded, forKey: historyKey)
    }

    // MARK: - Template Management

    func addTemplate(_ template: CustomTemplate) {
        templates.append(template)
        saveTemplates()
    }

    func updateTemplate(_ template: CustomTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            saveTemplates()
        }
    }

    func deleteTemplate(_ template: CustomTemplate) {
        templates.removeAll { $0.id == template.id }
        saveTemplates()
    }

    func templatesForMode(_ mode: PromptMode) -> [CustomTemplate] {
        templates.filter { $0.mode == mode }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private func loadTemplates() {
        guard let data = defaults.data(forKey: templatesKey),
              let decoded = try? JSONDecoder().decode([CustomTemplate].self, from: data) else {
            return
        }
        templates = decoded
    }

    private func saveTemplates() {
        guard let encoded = try? JSONEncoder().encode(templates) else { return }
        defaults.set(encoded, forKey: templatesKey)
    }

    private func seedDefaultTemplatesIfNeeded() {
        let hasDefaults = templates.contains { $0.isDefault }
        if !hasDefaults {
            templates = DefaultTemplates.createDefaults()
            saveTemplates()
        }
    }
}
