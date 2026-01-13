import Foundation

struct PromptHistory: Codable, Identifiable, Equatable {
    var id: UUID
    var prompt: String
    var generatedOutput: String?
    var timestamp: Date
    var isFavorite: Bool
    var isArchived: Bool

    init(id: UUID = UUID(), prompt: String, generatedOutput: String? = nil, timestamp: Date = Date(), isFavorite: Bool = false, isArchived: Bool = false) {
        self.id = id
        self.prompt = prompt
        self.generatedOutput = generatedOutput
        self.timestamp = timestamp
        self.isFavorite = isFavorite
        self.isArchived = isArchived
    }

    /// Whether this history item has a generated result
    var hasResult: Bool {
        generatedOutput != nil && !generatedOutput!.isEmpty
    }
}
