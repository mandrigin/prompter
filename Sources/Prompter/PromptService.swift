import Foundation

/// Represents the three variants of generated prompts
struct PromptVariants: Codable, Equatable {
    let primary: String
    let strict: String
    let exploratory: String
}

/// Errors that can occur during prompt generation
enum PromptServiceError: LocalizedError {
    case claudeNotFound
    case executionFailed(String)
    case invalidJSON(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .claudeNotFound:
            return "Claude CLI not found. Please install Claude Code."
        case .executionFailed(let message):
            return "Claude execution failed: \(message)"
        case .invalidJSON(let details):
            return "Invalid JSON response: \(details)"
        case .timeout:
            return "Claude request timed out"
        }
    }
}

/// Thread-safe string collector for async operations
private final class OutputCollector: @unchecked Sendable {
    private var output = ""
    private let lock = NSLock()

    func append(_ chunk: String) {
        lock.lock()
        defer { lock.unlock() }
        output += chunk
    }

    var value: String {
        lock.lock()
        defer { lock.unlock() }
        return output
    }
}

/// Service for generating prompt variants using Claude Code CLI
actor PromptService {
    private let claudePath: String
    private let timeoutSeconds: Double

    /// JSON schema for the expected response format
    private let responseSchema = """
    {
        "type": "object",
        "properties": {
            "primary": {
                "type": "string",
                "description": "The main recommended prompt, balanced for general use"
            },
            "strict": {
                "type": "string",
                "description": "A more constrained, conservative version of the prompt"
            },
            "exploratory": {
                "type": "string",
                "description": "A more creative, expansive version of the prompt"
            }
        },
        "required": ["primary", "strict", "exploratory"]
    }
    """

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

    /// Generate prompt variants for the given user input
    func generateVariants(
        for userInput: String,
        model: String = "sonnet",
        systemPrompt: String? = nil
    ) async throws -> PromptVariants {
        let effectiveSystemPrompt = systemPrompt ?? """
        You are a prompt engineering assistant. Given a user's rough idea or description, \
        generate three versions of an improved prompt:

        1. **primary**: A well-structured, balanced prompt suitable for general use
        2. **strict**: A more constrained version with explicit boundaries and limitations
        3. **exploratory**: A more open-ended version that encourages creative exploration

        Return ONLY valid JSON matching the schema. No explanations or markdown.
        """

        let userPrompt = "Generate prompt variants for: \(userInput)"

        return try await executeClaudeCommand(
            prompt: userPrompt,
            systemPrompt: effectiveSystemPrompt,
            model: model
        )
    }

    /// Execute claude CLI and parse the response
    private func executeClaudeCommand(
        prompt: String,
        systemPrompt: String,
        model: String
    ) async throws -> PromptVariants {
        // Verify claude exists
        guard FileManager.default.fileExists(atPath: claudePath) || claudePath == "claude" else {
            throw PromptServiceError.claudeNotFound
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: claudePath)
        process.arguments = [
            "--print",
            "--output-format", "json",
            "--model", model,
            "--system-prompt", systemPrompt,
            "--json-schema", responseSchema,
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

                    let variants = try parseResponse(stdoutData)
                    continuation.resume(returning: variants)
                } catch let error as PromptServiceError {
                    continuation.resume(throwing: error)
                } catch {
                    continuation.resume(throwing: PromptServiceError.executionFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Parse the JSON response from Claude
    private func parseResponse(_ data: Data) throws -> PromptVariants {
        // Claude's --output-format json wraps the result
        // Try to parse the claude output format first
        struct ClaudeResponse: Codable {
            let result: String?
            let error: String?
        }

        // First try to decode as Claude's wrapper format
        if let claudeResponse = try? JSONDecoder().decode(ClaudeResponse.self, from: data) {
            if let error = claudeResponse.error {
                throw PromptServiceError.executionFailed(error)
            }
            if let result = claudeResponse.result,
               let resultData = result.data(using: .utf8) {
                return try JSONDecoder().decode(PromptVariants.self, from: resultData)
            }
        }

        // Fall back to direct parsing
        do {
            return try JSONDecoder().decode(PromptVariants.self, from: data)
        } catch {
            let rawString = String(data: data, encoding: .utf8) ?? "<binary data>"
            throw PromptServiceError.invalidJSON("Could not parse: \(rawString.prefix(200))")
        }
    }
}

// MARK: - Streaming Support

extension PromptService {
    /// Stream prompt generation progress
    func generateVariantsStreaming(
        for userInput: String,
        model: String = "sonnet",
        systemPrompt: String? = nil,
        onProgress: @escaping (String) -> Void
    ) async throws -> PromptVariants {
        let effectiveSystemPrompt = systemPrompt ?? """
        You are a prompt engineering assistant. Given a user's rough idea or description, \
        generate three versions of an improved prompt:

        1. **primary**: A well-structured, balanced prompt suitable for general use
        2. **strict**: A more constrained version with explicit boundaries and limitations
        3. **exploratory**: A more open-ended version that encourages creative exploration

        Return ONLY valid JSON matching the schema. No explanations or markdown.
        """

        let userPrompt = "Generate prompt variants for: \(userInput)"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: claudePath)
        process.arguments = [
            "--print",
            "--output-format", "stream-json",
            "--model", model,
            "--system-prompt", effectiveSystemPrompt,
            "--json-schema", responseSchema,
            "--dangerously-skip-permissions",
            userPrompt
        ]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        // Thread-safe output collector
        let outputCollector = OutputCollector()

        // Read stdout asynchronously for streaming
        stdoutPipe.fileHandleForReading.readabilityHandler = { [outputCollector] handle in
            let data = handle.availableData
            if !data.isEmpty, let chunk = String(data: data, encoding: .utf8) {
                outputCollector.append(chunk)
                onProgress(chunk)
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            Task { [outputCollector] in
                do {
                    try process.run()

                    let timeoutTask = Task {
                        try await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                        if process.isRunning {
                            process.terminate()
                        }
                    }

                    process.waitUntilExit()
                    timeoutTask.cancel()

                    stdoutPipe.fileHandleForReading.readabilityHandler = nil

                    if process.terminationStatus != 0 {
                        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                        let stderr = String(data: stderrData, encoding: .utf8) ?? "Unknown error"
                        continuation.resume(throwing: PromptServiceError.executionFailed(stderr))
                        return
                    }

                    // Parse the final result from collected stream output
                    let variants = try parseStreamedResponse(outputCollector.value)
                    continuation.resume(returning: variants)
                } catch let error as PromptServiceError {
                    continuation.resume(throwing: error)
                } catch {
                    continuation.resume(throwing: PromptServiceError.executionFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Parse streamed JSON response
    private func parseStreamedResponse(_ output: String) throws -> PromptVariants {
        // Stream format includes multiple JSON objects, find the result
        let lines = output.components(separatedBy: "\n")

        for line in lines.reversed() {
            guard !line.isEmpty else { continue }

            if let data = line.data(using: .utf8) {
                // Try to decode as a message with result
                struct StreamMessage: Codable {
                    let type: String?
                    let result: String?
                }

                if let message = try? JSONDecoder().decode(StreamMessage.self, from: data),
                   message.type == "result",
                   let result = message.result,
                   let resultData = result.data(using: .utf8) {
                    return try JSONDecoder().decode(PromptVariants.self, from: resultData)
                }

                // Try direct decode
                if let variants = try? JSONDecoder().decode(PromptVariants.self, from: data) {
                    return variants
                }
            }
        }

        throw PromptServiceError.invalidJSON("No valid result found in stream output")
    }
}
