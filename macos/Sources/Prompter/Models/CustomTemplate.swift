import Foundation

struct CustomTemplate: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String
    var content: String
    var isDefault: Bool
    var sortOrder: Int

    init(id: UUID = UUID(), name: String, content: String, isDefault: Bool = false, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.content = content
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }
}

struct DefaultTemplates {
    static let templates: [(name: String, content: String)] = [
        ("Code Review", "Review this code for best practices, potential bugs, and improvements:"),
        ("Explain Code", "Explain what this code does in clear, simple terms:"),
        ("Debug Help", "Help me debug this issue:"),
        ("Quick Fix", "Fix this code with minimal changes:"),
        ("Refactor", "Refactor this to be more concise and readable:"),
        ("Architecture", "Suggest architectural improvements for:"),
        ("Best Practices", "What are the best practices for:"),
        ("Write Tests", "Write unit tests for this code:"),
        ("Business Research", "Research and analyze the following business topic, including market trends, competitors, and strategic insights:"),
        ("Technical Research", "Research the following technical topic, including documentation, implementation patterns, and best practices:"),
    ]

    static func createDefaults() -> [CustomTemplate] {
        templates.enumerated().map { index, template in
            CustomTemplate(
                name: template.name,
                content: template.content,
                isDefault: true,
                sortOrder: index
            )
        }
    }
}
