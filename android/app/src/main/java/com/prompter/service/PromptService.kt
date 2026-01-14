package com.prompter.service

import com.google.gson.Gson
import com.prompter.data.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.suspendCancellableCoroutine
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.BufferedReader
import java.io.IOException
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class PromptService(
    private val apiKeyManager: ApiKeyManager,
    private val settingsProvider: (() -> Settings)? = null
) {
    private val gson = Gson()

    private val currentProvider: AIProvider
        get() = settingsProvider?.invoke()?.provider ?: AIProvider.OPENAI

    private val currentApiKey: String?
        get() = settingsProvider?.invoke()?.let { settings ->
            when (settings.provider) {
                AIProvider.OPENAI -> settings.openaiApiKey.takeIf { it.isNotBlank() }
                AIProvider.CLAUDE -> settings.claudeApiKey.takeIf { it.isNotBlank() }
            }
        } ?: apiKeyManager.apiKey

    private val currentModel: String
        get() = settingsProvider?.invoke()?.model ?: apiKeyManager.model

    private val client = OkHttpClient.Builder()
        .connectTimeout(CONNECT_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .readTimeout(READ_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .writeTimeout(WRITE_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .build()

    suspend fun generatePrompt(
        userPrompt: String,
        systemPrompt: String
    ): ApiResult<String> {
        val apiKey = currentApiKey
            ?: return ApiResult.Error("API key not configured")

        return when (currentProvider) {
            AIProvider.OPENAI -> generatePromptOpenAI(apiKey, userPrompt, systemPrompt)
            AIProvider.CLAUDE -> generatePromptClaude(apiKey, userPrompt, systemPrompt)
        }
    }

    private suspend fun generatePromptOpenAI(
        apiKey: String,
        userPrompt: String,
        systemPrompt: String
    ): ApiResult<String> {
        val request = ChatCompletionRequest(
            model = currentModel,
            messages = listOf(
                ChatMessage.system(systemPrompt),
                ChatMessage.user(userPrompt)
            ),
            stream = false
        )

        return try {
            val response = executeOpenAIRequest(apiKey, request)
            val content = response.choices.firstOrNull()?.message?.content
                ?: return ApiResult.Error("No response content")
            ApiResult.Success(content)
        } catch (e: ApiException) {
            ApiResult.Error(e.message ?: "Unknown error", e.code)
        } catch (e: IOException) {
            ApiResult.Error("Network error: ${e.message}")
        } catch (e: Exception) {
            ApiResult.Error("Unexpected error: ${e.message}")
        }
    }

    private suspend fun generatePromptClaude(
        apiKey: String,
        userPrompt: String,
        systemPrompt: String
    ): ApiResult<String> {
        val request = ClaudeMessagesRequest(
            model = currentModel,
            messages = listOf(ClaudeMessage.user(userPrompt)),
            system = systemPrompt,
            stream = false
        )

        return try {
            val response = executeClaudeRequest(apiKey, request)
            val content = response.content.firstOrNull { it.type == "text" }?.text
                ?: return ApiResult.Error("No response content")
            ApiResult.Success(content)
        } catch (e: ApiException) {
            ApiResult.Error(e.message ?: "Unknown error", e.code)
        } catch (e: IOException) {
            ApiResult.Error("Network error: ${e.message}")
        } catch (e: Exception) {
            ApiResult.Error("Unexpected error: ${e.message}")
        }
    }

    fun generatePromptStream(
        userPrompt: String,
        systemPrompt: String
    ): Flow<StreamEvent> = flow {
        val apiKey = currentApiKey
        if (apiKey == null) {
            emit(StreamEvent.Error("API key not configured"))
            return@flow
        }

        try {
            emit(StreamEvent.Started)
            when (currentProvider) {
                AIProvider.OPENAI -> {
                    val request = ChatCompletionRequest(
                        model = currentModel,
                        messages = listOf(
                            ChatMessage.system(systemPrompt),
                            ChatMessage.user(userPrompt)
                        ),
                        stream = true
                    )
                    executeOpenAIStreamingRequest(apiKey, request).collect { chunk ->
                        emit(chunk)
                    }
                }
                AIProvider.CLAUDE -> {
                    val request = ClaudeMessagesRequest(
                        model = currentModel,
                        messages = listOf(ClaudeMessage.user(userPrompt)),
                        system = systemPrompt,
                        stream = true
                    )
                    executeClaudeStreamingRequest(apiKey, request).collect { chunk ->
                        emit(chunk)
                    }
                }
            }
            emit(StreamEvent.Completed)
        } catch (e: ApiException) {
            emit(StreamEvent.Error(e.message ?: "Unknown error"))
        } catch (e: IOException) {
            emit(StreamEvent.Error("Network error: ${e.message}"))
        } catch (e: Exception) {
            emit(StreamEvent.Error("Unexpected error: ${e.message}"))
        }
    }.flowOn(Dispatchers.IO)

    private suspend fun executeOpenAIRequest(
        apiKey: String,
        chatRequest: ChatCompletionRequest
    ): ChatCompletionResponse = suspendCancellableCoroutine { continuation ->
        val jsonBody = gson.toJson(chatRequest)
        val requestBody = jsonBody.toRequestBody(JSON_MEDIA_TYPE)

        val request = Request.Builder()
            .url(OPENAI_API_URL)
            .header("Authorization", "Bearer $apiKey")
            .header("Content-Type", "application/json")
            .post(requestBody)
            .build()

        val call = client.newCall(request)

        continuation.invokeOnCancellation {
            call.cancel()
        }

        call.enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                if (continuation.isActive) {
                    continuation.resumeWithException(e)
                }
            }

            override fun onResponse(call: Call, response: Response) {
                response.use { resp ->
                    val body = resp.body?.string()

                    if (!resp.isSuccessful) {
                        val error = try {
                            body?.let { gson.fromJson(it, OpenAIError::class.java) }
                        } catch (e: Exception) {
                            null
                        }
                        val message = error?.error?.message ?: "HTTP ${resp.code}: ${resp.message}"
                        if (continuation.isActive) {
                            continuation.resumeWithException(ApiException(message, resp.code))
                        }
                        return
                    }

                    if (body == null) {
                        if (continuation.isActive) {
                            continuation.resumeWithException(ApiException("Empty response body"))
                        }
                        return
                    }

                    try {
                        val result = gson.fromJson(body, ChatCompletionResponse::class.java)
                        if (continuation.isActive) {
                            continuation.resume(result)
                        }
                    } catch (e: Exception) {
                        if (continuation.isActive) {
                            continuation.resumeWithException(ApiException("Failed to parse response: ${e.message}"))
                        }
                    }
                }
            }
        })
    }

    private fun executeOpenAIStreamingRequest(
        apiKey: String,
        chatRequest: ChatCompletionRequest
    ): Flow<StreamEvent> = flow {
        val jsonBody = gson.toJson(chatRequest)
        val requestBody = jsonBody.toRequestBody(JSON_MEDIA_TYPE)

        val request = Request.Builder()
            .url(OPENAI_API_URL)
            .header("Authorization", "Bearer $apiKey")
            .header("Content-Type", "application/json")
            .header("Accept", "text/event-stream")
            .post(requestBody)
            .build()

        val response = client.newCall(request).execute()

        if (!response.isSuccessful) {
            val body = response.body?.string()
            val error = try {
                body?.let { gson.fromJson(it, OpenAIError::class.java) }
            } catch (e: Exception) {
                null
            }
            val message = error?.error?.message ?: "HTTP ${response.code}: ${response.message}"
            throw ApiException(message, response.code)
        }

        val reader = response.body?.source()?.inputStream()?.bufferedReader()
            ?: throw ApiException("Empty response body")

        try {
            parseOpenAISSEStream(reader).collect { event ->
                emit(event)
            }
        } finally {
            reader.close()
            response.close()
        }
    }.flowOn(Dispatchers.IO)

    private fun parseOpenAISSEStream(reader: BufferedReader): Flow<StreamEvent> = flow {
        var line: String?
        while (reader.readLine().also { line = it } != null) {
            val currentLine = line ?: continue

            if (currentLine.startsWith("data: ")) {
                val data = currentLine.removePrefix("data: ").trim()

                if (data == "[DONE]") {
                    break
                }

                try {
                    val chunk = gson.fromJson(data, ChatCompletionChunk::class.java)
                    val content = chunk.choices.firstOrNull()?.delta?.content
                    if (content != null) {
                        emit(StreamEvent.Content(content))
                    }
                } catch (e: Exception) {
                    // Skip malformed chunks
                }
            }
        }
    }

    // Claude API methods

    private suspend fun executeClaudeRequest(
        apiKey: String,
        claudeRequest: ClaudeMessagesRequest
    ): ClaudeMessagesResponse = suspendCancellableCoroutine { continuation ->
        val jsonBody = gson.toJson(claudeRequest)
        val requestBody = jsonBody.toRequestBody(JSON_MEDIA_TYPE)

        val request = Request.Builder()
            .url(CLAUDE_API_URL)
            .header("x-api-key", apiKey)
            .header("anthropic-version", CLAUDE_API_VERSION)
            .header("Content-Type", "application/json")
            .post(requestBody)
            .build()

        val call = client.newCall(request)

        continuation.invokeOnCancellation {
            call.cancel()
        }

        call.enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                if (continuation.isActive) {
                    continuation.resumeWithException(e)
                }
            }

            override fun onResponse(call: Call, response: Response) {
                response.use { resp ->
                    val body = resp.body?.string()

                    if (!resp.isSuccessful) {
                        val error = try {
                            body?.let { gson.fromJson(it, ClaudeError::class.java) }
                        } catch (e: Exception) {
                            null
                        }
                        val message = error?.error?.message ?: "HTTP ${resp.code}: ${resp.message}"
                        if (continuation.isActive) {
                            continuation.resumeWithException(ApiException(message, resp.code))
                        }
                        return
                    }

                    if (body == null) {
                        if (continuation.isActive) {
                            continuation.resumeWithException(ApiException("Empty response body"))
                        }
                        return
                    }

                    try {
                        val result = gson.fromJson(body, ClaudeMessagesResponse::class.java)
                        if (continuation.isActive) {
                            continuation.resume(result)
                        }
                    } catch (e: Exception) {
                        if (continuation.isActive) {
                            continuation.resumeWithException(ApiException("Failed to parse response: ${e.message}"))
                        }
                    }
                }
            }
        })
    }

    private fun executeClaudeStreamingRequest(
        apiKey: String,
        claudeRequest: ClaudeMessagesRequest
    ): Flow<StreamEvent> = flow {
        val jsonBody = gson.toJson(claudeRequest)
        val requestBody = jsonBody.toRequestBody(JSON_MEDIA_TYPE)

        val request = Request.Builder()
            .url(CLAUDE_API_URL)
            .header("x-api-key", apiKey)
            .header("anthropic-version", CLAUDE_API_VERSION)
            .header("Content-Type", "application/json")
            .header("Accept", "text/event-stream")
            .post(requestBody)
            .build()

        val response = client.newCall(request).execute()

        if (!response.isSuccessful) {
            val body = response.body?.string()
            val error = try {
                body?.let { gson.fromJson(it, ClaudeError::class.java) }
            } catch (e: Exception) {
                null
            }
            val message = error?.error?.message ?: "HTTP ${response.code}: ${response.message}"
            throw ApiException(message, response.code)
        }

        val reader = response.body?.source()?.inputStream()?.bufferedReader()
            ?: throw ApiException("Empty response body")

        try {
            parseClaudeSSEStream(reader).collect { event ->
                emit(event)
            }
        } finally {
            reader.close()
            response.close()
        }
    }.flowOn(Dispatchers.IO)

    private fun parseClaudeSSEStream(reader: BufferedReader): Flow<StreamEvent> = flow {
        var line: String?
        while (reader.readLine().also { line = it } != null) {
            val currentLine = line ?: continue

            if (currentLine.startsWith("data: ")) {
                val data = currentLine.removePrefix("data: ").trim()

                try {
                    val event = gson.fromJson(data, ClaudeStreamEvent::class.java)
                    when (event.type) {
                        "content_block_delta" -> {
                            val text = event.delta?.text
                            if (text != null) {
                                emit(StreamEvent.Content(text))
                            }
                        }
                        "message_stop" -> {
                            break
                        }
                        "error" -> {
                            throw ApiException("Stream error")
                        }
                    }
                } catch (e: ApiException) {
                    throw e
                } catch (e: Exception) {
                    // Skip malformed chunks
                }
            }
        }
    }

    companion object {
        private const val OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"
        private const val CLAUDE_API_URL = "https://api.anthropic.com/v1/messages"
        private const val CLAUDE_API_VERSION = "2023-06-01"
        private val JSON_MEDIA_TYPE = "application/json".toMediaType()
        private const val CONNECT_TIMEOUT_SECONDS = 30L
        private const val READ_TIMEOUT_SECONDS = 120L
        private const val WRITE_TIMEOUT_SECONDS = 30L
    }
}

sealed class StreamEvent {
    data object Started : StreamEvent()
    data class Content(val text: String) : StreamEvent()
    data object Completed : StreamEvent()
    data class Error(val message: String) : StreamEvent()
}

class ApiException(
    message: String,
    val code: Int? = null
) : Exception(message)
