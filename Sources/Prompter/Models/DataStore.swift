import Foundation
import SwiftUI

@MainActor
class DataStore: ObservableObject {
    @Published var history: [PromptHistory] = []
    @Published var templates: [CustomTemplate] = []
    /// Set of item IDs currently generating (supports parallel generation)
    @Published var generatingIds: Set<UUID> = []

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
        generatingIds.remove(item.id)
        history.removeAll { $0.id == item.id }
        saveHistory()
    }

    func updateHistoryOutput(id: UUID, output: String) {
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].addVersion(output: output)
            saveHistory()
        }
    }

    /// Find existing history item with the same prompt text
    func findExistingPrompt(_ promptText: String) -> PromptHistory? {
        let normalizedPrompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        return history.first { $0.prompt.trimmingCharacters(in: .whitespacesAndNewlines) == normalizedPrompt }
    }

    /// Add a new version to an existing history item
    func addVersionToHistory(id: UUID, output: String) {
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].addVersion(output: output)
            // Move to top of history
            let item = history.remove(at: index)
            history.insert(item, at: 0)
            saveHistory()
        }
    }

    func updateHistoryStatus(id: UUID, status: GenerationStatus, error: String? = nil) {
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].generationStatus = status
            if let error = error {
                history[index].errorMessage = error
            }
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
            history[index].addVersion(output: output)
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

    func startGeneration(id: UUID, length: PromptLength) {
        generatingIds.insert(id)
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].generationStatus = .generating
            history[index].activeGeneration = length
            saveHistory()
        }
    }

    func completeGeneration(id: UUID, output: String) {
        generatingIds.remove(id)
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].generatedOutput = output
            history[index].generationStatus = .completed
            history[index].errorMessage = nil
            history[index].activeGeneration = nil
            saveHistory()
        }
    }

    func failGeneration(id: UUID, error: String) {
        generatingIds.remove(id)
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].generationStatus = .failed
            history[index].errorMessage = error
            history[index].activeGeneration = nil
            saveHistory()
        }
    }

    func cancelGeneration(id: UUID) {
        generatingIds.remove(id)
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].generationStatus = .cancelled
            history[index].activeGeneration = nil
            saveHistory()
        }
    }

    /// Check if a specific item is currently generating
    func isGenerating(id: UUID) -> Bool {
        generatingIds.contains(id)
    }

    /// Get the active generation type for an item
    func activeGeneration(for id: UUID) -> PromptLength? {
        history.first { $0.id == id }?.activeGeneration
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
                history[i].activeGeneration = nil
            }
        }
        generatingIds.removeAll()
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
