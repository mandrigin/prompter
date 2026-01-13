import Foundation

/// Status of prompt generation
enum GenerationStatus: String, Codable {
    case pending
    case generating
    case completed
    case failed
    case cancelled
}

/// A single version of a generated prompt output
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
    var generatedOutput: String?
    var timestamp: Date
    var isFavorite: Bool
    var isArchived: Bool
    var generationStatus: GenerationStatus?
    var generationError: String?
    var versions: [PromptVersion]
    var selectedVersionIndex: Int

    init(id: UUID = UUID(), prompt: String, generatedOutput: String? = nil, timestamp: Date = Date(), isFavorite: Bool = false, isArchived: Bool = false, generationStatus: GenerationStatus? = nil, generationError: String? = nil, versions: [PromptVersion] = [], selectedVersionIndex: Int = 0) {
        self.id = id
        self.prompt = prompt
        self.generatedOutput = generatedOutput
        self.timestamp = timestamp
        self.isFavorite = isFavorite
        self.isArchived = isArchived
        self.generationStatus = generationStatus
        self.generationError = generationError
        self.versions = versions
        self.selectedVersionIndex = selectedVersionIndex
    }

    /// Whether this history item has a generated result
    var hasResult: Bool {
        !versions.isEmpty || (generatedOutput != nil && !generatedOutput!.isEmpty)
    }

    /// The currently selected version's output, or legacy generatedOutput
    var currentOutput: String? {
        if !versions.isEmpty && selectedVersionIndex < versions.count {
            return versions[selectedVersionIndex].output
        }
        return generatedOutput
    }

    /// Number of versions available
    var versionCount: Int {
        versions.isEmpty ? (generatedOutput != nil ? 1 : 0) : versions.count
    }

    /// Add a new version with the given output
    mutating func addVersion(output: String) {
        let version = PromptVersion(output: output)
        versions.append(version)
        selectedVersionIndex = versions.count - 1
        // Keep generatedOutput in sync for backwards compatibility
        generatedOutput = output
    }
}
