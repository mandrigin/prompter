import Foundation
import SwiftUI

@MainActor
class DataStore: ObservableObject {
    @Published var history: [PromptHistory] = []
    @Published var templates: [CustomTemplate] = []
    @Published var generatingItemId: UUID? = nil

    private let historyKey = "promptHistory"
    private let templatesKey = "customTemplates"
    private let defaults = UserDefaults.standard

    init() {
        loadHistory()
        loadTemplates()
        seedDefaultTemplatesIfNeeded()
        // Reset any stuck "generating" statuses on startup
        resetStuckGenerations()
    }

    // MARK: - History Management

    func addHistoryItem(_ item: PromptHistory) {
        history.insert(item, at: 0)
        saveHistory()
    }

    func deleteHistoryItem(_ item: PromptHistory) {
        if generatingItemId == item.id {
            generatingItemId = nil
        }
        history.removeAll { $0.id == item.id }
        saveHistory()
    }

    func updateHistoryOutput(id: UUID, output: String) {
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].generatedOutput = output
            saveHistory()
        }
    }

    func archiveHistoryItem(_ item: PromptHistory) {
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            history[index].isArchived = true
            saveHistory()
        }
    }

    func unarchiveHistoryItem(_ item: PromptHistory) {
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            history[index].isArchived = false
            saveHistory()
        }
    }

    func updateHistoryItemOutput(_ item: PromptHistory, output: String) {
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            history[index].generatedOutput = output
            saveHistory()
        }
    }

    // MARK: - Generation Status Management

    func updateGenerationStatus(id: UUID, status: GenerationStatus, error: String? = nil) {
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].generationStatus = status
            if let error = error {
                history[index].errorMessage = error
            }
            saveHistory()
        }
    }

    func startGeneration(id: UUID) {
        generatingItemId = id
        updateGenerationStatus(id: id, status: .generating)
    }

    func completeGeneration(id: UUID, output: String) {
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].generatedOutput = output
            history[index].generationStatus = .completed
            history[index].errorMessage = nil
            saveHistory()
        }
        if generatingItemId == id {
            generatingItemId = nil
        }
    }

    func failGeneration(id: UUID, error: String) {
        updateGenerationStatus(id: id, status: .failed, error: error)
        if generatingItemId == id {
            generatingItemId = nil
        }
    }

    func cancelGeneration(id: UUID) {
        // Reset to pending if cancelled
        updateGenerationStatus(id: id, status: .pending)
        if generatingItemId == id {
            generatingItemId = nil
        }
    }

    /// Check if a specific item is currently generating
    func isGenerating(id: UUID) -> Bool {
        generatingItemId == id
    }

    /// Get the history item by ID
    func historyItem(byId id: UUID) -> PromptHistory? {
        history.first { $0.id == id }
    }

    private func resetStuckGenerations() {
        // On startup, reset any items stuck in "generating" state to "pending"
        for i in history.indices {
            if history[i].generationStatus == .generating {
                history[i].generationStatus = .pending
            }
        }
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

    var sortedTemplates: [CustomTemplate] {
        templates.sorted { $0.sortOrder < $1.sortOrder }
    }

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
