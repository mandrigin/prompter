import Foundation

struct PromptHistory: Codable, Identifiable, Equatable {
    var id: UUID
    var prompt: String
    var timestamp: Date
    var isFavorite: Bool
    var isArchived: Bool

    init(id: UUID = UUID(), prompt: String, timestamp: Date = Date(), isFavorite: Bool = false, isArchived: Bool = false) {
        self.id = id
        self.prompt = prompt
        self.timestamp = timestamp
        self.isFavorite = isFavorite
        self.isArchived = isArchived
    }
}
