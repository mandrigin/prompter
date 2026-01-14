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
    private val apiKeyManager: ApiKeyManager
) {
    private val gson = Gson()

    private val client = OkHttpClient.Builder()
        .connectTimeout(CONNECT_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .readTimeout(READ_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .writeTimeout(WRITE_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .build()

    suspend fun generatePrompt(
        userPrompt: String,
        systemPrompt: String
    ): ApiResult<String> {
        val apiKey = apiKeyManager.apiKey
            ?: return ApiResult.Error("API key not configured")

        val request = ChatCompletionRequest(
            model = apiKeyManager.model,
            messages = listOf(
                ChatMessage.system(systemPrompt),
                ChatMessage.user(userPrompt)
            ),
            stream = false
        )

        return try {
            val response = executeRequest(apiKey, request)
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

    fun generatePromptStream(
        userPrompt: String,
        systemPrompt: String
    ): Flow<StreamEvent> = flow {
        val apiKey = apiKeyManager.apiKey
        if (apiKey == null) {
            emit(StreamEvent.Error("API key not configured"))
            return@flow
        }

        val request = ChatCompletionRequest(
            model = apiKeyManager.model,
            messages = listOf(
                ChatMessage.system(systemPrompt),
                ChatMessage.user(userPrompt)
            ),
            stream = true
        )

        try {
            emit(StreamEvent.Started)
            executeStreamingRequest(apiKey, request).collect { chunk ->
                emit(chunk)
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

    private suspend fun executeRequest(
        apiKey: String,
        chatRequest: ChatCompletionRequest
    ): ChatCompletionResponse = suspendCancellableCoroutine { continuation ->
        val jsonBody = gson.toJson(chatRequest)
        val requestBody = jsonBody.toRequestBody(JSON_MEDIA_TYPE)

        val request = Request.Builder()
            .url(API_URL)
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

    private fun executeStreamingRequest(
        apiKey: String,
        chatRequest: ChatCompletionRequest
    ): Flow<StreamEvent> = flow {
        val jsonBody = gson.toJson(chatRequest)
        val requestBody = jsonBody.toRequestBody(JSON_MEDIA_TYPE)

        val request = Request.Builder()
            .url(API_URL)
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
            parseSSEStream(reader).collect { event ->
                emit(event)
            }
        } finally {
            reader.close()
            response.close()
        }
    }.flowOn(Dispatchers.IO)

    private fun parseSSEStream(reader: BufferedReader): Flow<StreamEvent> = flow {
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

    companion object {
        private const val API_URL = "https://api.openai.com/v1/chat/completions"
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
