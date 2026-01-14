import Foundation

/// Errors that can occur during prompt generation
enum PromptServiceError: LocalizedError {
    case claudeNotFound
    case executionFailed(String)
    case emptyResponse
    case timeout

    var errorDescription: String? {
        switch self {
        case .claudeNotFound:
            return "Claude CLI not found. Please install Claude Code."
        case .executionFailed(let message):
            return "Claude execution failed: \(message)"
        case .emptyResponse:
            return "Claude returned an empty response"
        case .timeout:
            return "Claude request timed out"
        }
    }
}

/// Service for generating improved prompts using Claude Code CLI
actor PromptService {
    private let claudePath: String
    private let timeoutSeconds: Double

    init(claudePath: String? = nil, timeoutSeconds: Double = 120) {
        self.claudePath = claudePath ?? Self.findClaudePath()
        self.timeoutSeconds = timeoutSeconds
    }

    /// Find the claude CLI in common locations
    private static func findClaudePath() -> String {
        let possiblePaths = [
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
            NSHomeDirectory() + "/.local/bin/claude",
            "/usr/bin/claude"
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        // Fall back to PATH lookup
        return "claude"
    }

    /// Generate an improved prompt for the given user input
    func generatePrompt(
        for userInput: String,
        model: String = "sonnet",
        systemPrompt: String? = nil
    ) async throws -> String {
        let effectiveSystemPrompt = systemPrompt ?? """
        You are a prompt engineering assistant. Given a user's rough idea or description, \
        generate an improved, well-structured prompt.

        Format your response in markdown with:
        - A clear, actionable prompt
        - Key considerations or context if relevant
        - Example usage if helpful

        Be concise but thorough. Focus on making the prompt effective for AI assistants.
        """

        let userPrompt = "Improve this prompt: \(userInput)"

        return try await executeClaudeCommand(
            prompt: userPrompt,
            systemPrompt: effectiveSystemPrompt,
            model: model
        )
    }

    /// Execute claude CLI and return the response
    private func executeClaudeCommand(
        prompt: String,
        systemPrompt: String,
        model: String
    ) async throws -> String {
        // Verify claude exists
        guard FileManager.default.fileExists(atPath: claudePath) || claudePath == "claude" else {
            throw PromptServiceError.claudeNotFound
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: claudePath)
        process.arguments = [
            "--print",
            "--model", model,
            "--system-prompt", systemPrompt,
            "--dangerously-skip-permissions",
            prompt
        ]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try process.run()

                    // Set up timeout
                    let timeoutTask = Task {
                        try await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                        if process.isRunning {
                            process.terminate()
                        }
                    }

                    process.waitUntilExit()
                    timeoutTask.cancel()

                    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                    if process.terminationStatus != 0 {
                        let stderr = String(data: stderrData, encoding: .utf8) ?? "Unknown error"
                        continuation.resume(throwing: PromptServiceError.executionFailed(stderr))
                        return
                    }

                    guard let output = String(data: stdoutData, encoding: .utf8),
                          !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        continuation.resume(throwing: PromptServiceError.emptyResponse)
                        return
                    }

                    continuation.resume(returning: output.trimmingCharacters(in: .whitespacesAndNewlines))
                } catch let error as PromptServiceError {
                    continuation.resume(throwing: error)
                } catch {
                    continuation.resume(throwing: PromptServiceError.executionFailed(error.localizedDescription))
                }
            }
        }
    }
}
