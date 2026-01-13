import Foundation

/// Status of a prompt generation request
enum GenerationStatus: Codable, Equatable {
    case pending
    case generating
    case completed
    case failed
    case cancelled
}

/// Represents a single prompt generation request
struct GenerationRequest: Identifiable, Equatable {
    let id: UUID
    let inputPrompt: String
    let systemPrompt: String
    let timestamp: Date
    var status: GenerationStatus
    var output: String?
    var error: String?

    init(
        id: UUID = UUID(),
        inputPrompt: String,
        systemPrompt: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.inputPrompt = inputPrompt
        self.systemPrompt = systemPrompt
        self.timestamp = timestamp
        self.status = .pending
        self.output = nil
        self.error = nil
    }

    /// Preview of the input prompt for display
    var promptPreview: String {
        let trimmed = inputPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 50 {
            return trimmed
        }
        return String(trimmed.prefix(47)) + "..."
    }
}
