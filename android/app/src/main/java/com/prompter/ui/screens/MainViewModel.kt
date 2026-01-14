package com.prompter.ui.screens

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.prompter.data.ApiKeyManager
import com.prompter.data.ApiResult
import com.prompter.service.PromptService
import com.prompter.service.StreamEvent
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class MainUiState(
    val promptText: String = "",
    val generatedOutput: String = "",
    val isGenerating: Boolean = false,
    val error: String? = null,
    val hasApiKey: Boolean = false
)

enum class PromptLength {
    SHORT, LONG
}

class MainViewModel(application: Application) : AndroidViewModel(application) {

    private val apiKeyManager = ApiKeyManager(application)
    private val promptService = PromptService(apiKeyManager)

    private val _uiState = MutableStateFlow(MainUiState(hasApiKey = apiKeyManager.hasApiKey))
    val uiState: StateFlow<MainUiState> = _uiState.asStateFlow()

    private var generationJob: Job? = null

    fun updatePromptText(text: String) {
        _uiState.update { it.copy(promptText = text) }
    }

    fun generatePrompt(length: PromptLength) {
        val prompt = _uiState.value.promptText.trim()
        if (prompt.isEmpty()) return

        generationJob?.cancel()
        _uiState.update { it.copy(isGenerating = true, error = null, generatedOutput = "") }

        val systemPrompt = when (length) {
            PromptLength.SHORT -> SHORT_SYSTEM_PROMPT
            PromptLength.LONG -> LONG_SYSTEM_PROMPT
        }

        generationJob = viewModelScope.launch {
            promptService.generatePromptStream(prompt, systemPrompt).collect { event ->
                when (event) {
                    is StreamEvent.Started -> {
                        _uiState.update { it.copy(isGenerating = true) }
                    }
                    is StreamEvent.Content -> {
                        _uiState.update { state ->
                            state.copy(generatedOutput = state.generatedOutput + event.text)
                        }
                    }
                    is StreamEvent.Completed -> {
                        _uiState.update { it.copy(isGenerating = false) }
                    }
                    is StreamEvent.Error -> {
                        _uiState.update { it.copy(isGenerating = false, error = event.message) }
                    }
                }
            }
        }
    }

    fun cancelGeneration() {
        generationJob?.cancel()
        generationJob = null
        _uiState.update { it.copy(isGenerating = false) }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun clearOutput() {
        _uiState.update { it.copy(generatedOutput = "", promptText = "") }
    }

    fun setApiKey(key: String) {
        apiKeyManager.apiKey = key
        _uiState.update { it.copy(hasApiKey = apiKeyManager.hasApiKey) }
    }

    fun checkApiKey() {
        _uiState.update { it.copy(hasApiKey = apiKeyManager.hasApiKey) }
    }

    companion object {
        private const val SHORT_SYSTEM_PROMPT = """You are a prompt engineer. Transform the user's rough idea into a clear, focused prompt optimized for LLMs. Be concise - aim for 2-3 sentences that capture the core intent. Focus on clarity and specificity."""

        private const val LONG_SYSTEM_PROMPT = """You are an expert prompt engineer. Transform the user's rough idea into a comprehensive, well-structured prompt optimized for large language models.

Your improved prompt should:
1. Clearly define the task and desired outcome
2. Specify the format, style, and tone expected
3. Include relevant constraints and requirements
4. Add helpful context that guides the AI
5. Structure complex requests into clear steps

Be thorough but not verbose. Aim for precision and completeness."""
    }
}
