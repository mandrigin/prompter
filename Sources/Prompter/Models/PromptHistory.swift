import Foundation

/// Status of prompt generation
enum GenerationStatus: String, Codable {
    case pending
    case generating
    case completed
    case failed
}

struct PromptHistory: Codable, Identifiable, Equatable {
    var id: UUID
    var prompt: String
    var generatedOutput: String?
    var generationStatus: GenerationStatus
    var errorMessage: String?
    var timestamp: Date
    var isFavorite: Bool
    var isArchived: Bool

    init(id: UUID = UUID(), prompt: String, generatedOutput: String? = nil, generationStatus: GenerationStatus = .pending, errorMessage: String? = nil, timestamp: Date = Date(), isFavorite: Bool = false, isArchived: Bool = false) {
        self.id = id
        self.prompt = prompt
        self.generatedOutput = generatedOutput
        self.generationStatus = generationStatus
        self.errorMessage = errorMessage
        self.timestamp = timestamp
        self.isFavorite = isFavorite
        self.isArchived = isArchived
    }

    /// Whether this history item has a generated result
    var hasResult: Bool {
        generatedOutput != nil && !generatedOutput!.isEmpty
    }
}
