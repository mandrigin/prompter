package com.prompter.data

import com.google.gson.annotations.SerializedName

// Request models

data class ChatCompletionRequest(
    val model: String,
    val messages: List<ChatMessage>,
    val stream: Boolean = false,
    val temperature: Double = 0.7,
    @SerializedName("max_tokens")
    val maxTokens: Int? = null
)

data class ChatMessage(
    val role: String,
    val content: String
) {
    companion object {
        fun system(content: String) = ChatMessage("system", content)
        fun user(content: String) = ChatMessage("user", content)
        fun assistant(content: String) = ChatMessage("assistant", content)
    }
}

// Response models

data class ChatCompletionResponse(
    val id: String,
    val `object`: String,
    val created: Long,
    val model: String,
    val choices: List<Choice>,
    val usage: Usage?
)

data class Choice(
    val index: Int,
    val message: ChatMessage?,
    val delta: Delta?,
    @SerializedName("finish_reason")
    val finishReason: String?
)

data class Delta(
    val role: String?,
    val content: String?
)

data class Usage(
    @SerializedName("prompt_tokens")
    val promptTokens: Int,
    @SerializedName("completion_tokens")
    val completionTokens: Int,
    @SerializedName("total_tokens")
    val totalTokens: Int
)

// Streaming response (Server-Sent Events)

data class ChatCompletionChunk(
    val id: String,
    val `object`: String,
    val created: Long,
    val model: String,
    val choices: List<Choice>
)

// Error response

data class OpenAIError(
    val error: ErrorDetails
)

data class ErrorDetails(
    val message: String,
    val type: String,
    val param: String?,
    val code: String?
)

// Result wrapper

sealed class ApiResult<out T> {
    data class Success<T>(val data: T) : ApiResult<T>()
    data class Error(val message: String, val code: Int? = null) : ApiResult<Nothing>()
    data object Loading : ApiResult<Nothing>()
}
