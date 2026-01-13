import Foundation

/// A single version of a generated output
struct GenerationVersion: Codable, Identifiable, Equatable {
    let id: UUID
    let output: String
    let timestamp: Date

    init(id: UUID = UUID(), output: String, timestamp: Date = Date()) {
        self.id = id
        self.output = output
        self.timestamp = timestamp
    }
}

struct PromptHistory: Codable, Identifiable, Equatable {
    var id: UUID
    var prompt: String
    var versions: [GenerationVersion]
    var timestamp: Date
    var isFavorite: Bool
    var isArchived: Bool

    init(id: UUID = UUID(), prompt: String, versions: [GenerationVersion] = [], timestamp: Date = Date(), isFavorite: Bool = false, isArchived: Bool = false) {
        self.id = id
        self.prompt = prompt
        self.versions = versions
        self.timestamp = timestamp
        self.isFavorite = isFavorite
        self.isArchived = isArchived
    }

    /// Whether this history item has any generated versions
    var hasResult: Bool {
        !versions.isEmpty
    }

    /// The latest generated output (most recent version)
    var latestOutput: String? {
        versions.last?.output
    }

    /// Number of versions
    var versionCount: Int {
        versions.count
    }

    /// Get output for a specific version index (0-based)
    func output(at index: Int) -> String? {
        guard index >= 0 && index < versions.count else { return nil }
        return versions[index].output
    }

    /// Add a new version
    mutating func addVersion(output: String) {
        let version = GenerationVersion(output: output)
        versions.append(version)
    }

    // Migration support: convert old generatedOutput to versions
    enum CodingKeys: String, CodingKey {
        case id, prompt, versions, timestamp, isFavorite, isArchived
        case generatedOutput // Legacy key for migration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        prompt = try container.decode(String.self, forKey: .prompt)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false

        // Try to decode versions array first
        if let decodedVersions = try? container.decode([GenerationVersion].self, forKey: .versions) {
            versions = decodedVersions
        } else if let legacyOutput = try? container.decodeIfPresent(String.self, forKey: .generatedOutput),
                  !legacyOutput.isEmpty {
            // Migrate from legacy single output format
            versions = [GenerationVersion(output: legacyOutput, timestamp: timestamp)]
        } else {
            versions = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(prompt, forKey: .prompt)
        try container.encode(versions, forKey: .versions)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(isArchived, forKey: .isArchived)
    }
}
