import Foundation

struct CustomTemplate: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String
    var content: String
    var mode: PromptMode
    var isDefault: Bool
    var sortOrder: Int

    init(id: UUID = UUID(), name: String, content: String, mode: PromptMode, isDefault: Bool = false, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.content = content
        self.mode = mode
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }
}

struct DefaultTemplates {
    static let templates: [(name: String, content: String, mode: PromptMode)] = [
        // Primary mode templates
        ("Code Review", "Review this code for best practices, potential bugs, and improvements:", .primary),
        ("Explain Code", "Explain what this code does in clear, simple terms:", .primary),
        ("Debug Help", "Help me debug this issue:", .primary),

        // Strict mode templates
        ("Quick Fix", "Fix this code with minimal changes:", .strict),
        ("Syntax Check", "Check syntax and fix errors:", .strict),
        ("Refactor", "Refactor this to be more concise:", .strict),

        // Exploratory mode templates
        ("Architecture", "Suggest architectural improvements for:", .exploratory),
        ("Alternatives", "What are alternative approaches to:", .exploratory),
        ("Best Practices", "What are the best practices for:", .exploratory),
    ]

    static func createDefaults() -> [CustomTemplate] {
        templates.enumerated().map { index, template in
            CustomTemplate(
                name: template.name,
                content: template.content,
                mode: template.mode,
                isDefault: true,
                sortOrder: index
            )
        }
    }
}
