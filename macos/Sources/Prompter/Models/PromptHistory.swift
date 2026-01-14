import Foundation

/// Status of prompt generation
enum GenerationStatus: String, Codable {
    case pending
    case generating
    case completed
    case failed
    case cancelled
}

/// A single version of generated output for a prompt
struct PromptVersion: Codable, Identifiable, Equatable {
    var id: UUID
    var output: String
    var timestamp: Date

    init(id: UUID = UUID(), output: String, timestamp: Date = Date()) {
        self.id = id
        self.output = output
        self.timestamp = timestamp
    }
}

struct PromptHistory: Codable, Identifiable, Equatable {
    var id: UUID
    var prompt: String
    var versions: [PromptVersion]
    var timestamp: Date
    var isFavorite: Bool
    var isArchived: Bool
    var generationStatus: GenerationStatus?
    var errorMessage: String?

    init(id: UUID = UUID(), prompt: String, generatedOutput: String? = nil, timestamp: Date = Date(), isFavorite: Bool = false, isArchived: Bool = false, generationStatus: GenerationStatus? = nil, errorMessage: String? = nil) {
        self.id = id
        self.prompt = prompt
        self.timestamp = timestamp
        self.isFavorite = isFavorite
        self.isArchived = isArchived
        self.generationStatus = generationStatus
        self.errorMessage = errorMessage

        // Initialize versions array, with initial version if output provided
        if let output = generatedOutput, !output.isEmpty {
            self.versions = [PromptVersion(output: output, timestamp: timestamp)]
        } else {
            self.versions = []
        }
    }

    /// The latest generated output (for backwards compatibility)
    var generatedOutput: String? {
        versions.last?.output
    }

    /// Whether this history item has a generated result
    var hasResult: Bool {
        !versions.isEmpty
    }

    /// Number of versions generated for this prompt
    var versionCount: Int {
        versions.count
    }

    /// Add a new version to this prompt's history
    mutating func addVersion(output: String) {
        let version = PromptVersion(output: output, timestamp: Date())
        versions.append(version)
    }
}
