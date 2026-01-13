import Foundation

struct PromptHistory: Codable, Identifiable, Equatable {
    var id: UUID
    var prompt: String
    var mode: PromptMode
    var timestamp: Date
    var isFavorite: Bool

    init(id: UUID = UUID(), prompt: String, mode: PromptMode, timestamp: Date = Date(), isFavorite: Bool = false) {
        self.id = id
        self.prompt = prompt
        self.mode = mode
        self.timestamp = timestamp
        self.isFavorite = isFavorite
    }
}

enum PromptMode: String, Codable, CaseIterable {
    case primary = "Primary"
    case strict = "Strict"
    case exploratory = "Exploratory"

    var description: String {
        switch self {
        case .primary:
            return "Balanced responses with good context"
        case .strict:
            return "Focused, concise responses"
        case .exploratory:
            return "Creative, expansive responses"
        }
    }
}
