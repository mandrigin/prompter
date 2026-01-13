import Foundation

/// Status of prompt generation
enum GenerationStatus: String, Codable {
    case pending
    case generating
    case completed
    case failed
    case cancelled
}

/// Type of prompt generation (short/concise vs long/detailed)
enum PromptLength: String, Codable {
    case short
    case long
}

struct PromptHistory: Codable, Identifiable, Equatable {
    var id: UUID
    var prompt: String
    var generatedOutput: String?
    var timestamp: Date
    var isFavorite: Bool
    var isArchived: Bool
    var generationStatus: GenerationStatus?
    var errorMessage: String?
    /// Which generation type is currently active (nil if not generating)
    var activeGeneration: PromptLength?

    init(id: UUID = UUID(), prompt: String, generatedOutput: String? = nil, timestamp: Date = Date(), isFavorite: Bool = false, isArchived: Bool = false, generationStatus: GenerationStatus? = nil, errorMessage: String? = nil, activeGeneration: PromptLength? = nil) {
        self.id = id
        self.prompt = prompt
        self.generatedOutput = generatedOutput
        self.timestamp = timestamp
        self.isFavorite = isFavorite
        self.isArchived = isArchived
        self.generationStatus = generationStatus
        self.errorMessage = errorMessage
        self.activeGeneration = activeGeneration
    }

    /// Whether this history item has a generated result
    var hasResult: Bool {
        generatedOutput != nil && !generatedOutput!.isEmpty
    }

    /// Add a new version (for now, just sets generatedOutput)
    mutating func addVersion(output: String) {
        generatedOutput = output
    }
}
