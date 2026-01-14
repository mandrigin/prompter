package com.prompter.ui.screens

import android.app.Application
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.prompter.data.ApiKeyManager
import com.prompter.data.SettingsRepository
import com.prompter.db.*
import com.prompter.service.PromptService
import com.prompter.service.StreamEvent
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.net.UnknownHostException
import java.net.SocketTimeoutException

data class MainUiState(
    val promptText: String = "",
    val generatedOutput: String = "",
    val isGenerating: Boolean = false,
    val error: String? = null,
    val hasApiKey: Boolean = false,
    val selectedHistoryId: String? = null,
    val selectedVersionIndex: Int = 0,
    val showDrawer: Boolean = false
)

enum class PromptLength {
    SHORT, LONG
}

class MainViewModel(application: Application) : AndroidViewModel(application) {

    private val settingsRepository = SettingsRepository(application)
    private val apiKeyManager = ApiKeyManager(application)
    private val promptService = PromptService(
        apiKeyManager,
        settingsProvider = { settingsRepository.settings.value }
    )
    private val database = PrompterDatabase.getDatabase(application)
    private val repository = PrompterRepository(
        database.promptHistoryDao(),
        database.customTemplateDao()
    )

    private val _uiState = MutableStateFlow(MainUiState(hasApiKey = settingsRepository.hasApiKey()))
    val uiState: StateFlow<MainUiState> = _uiState.asStateFlow()

    val history: StateFlow<List<PromptHistoryWithVersions>> = repository.allHistory
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val templates: StateFlow<List<CustomTemplateEntity>> = repository.allTemplates
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    private val generatingIds = MutableStateFlow<Set<String>>(emptySet())
    val generatingIdsFlow: StateFlow<Set<String>> = generatingIds.asStateFlow()

    private var generationJob: Job? = null
    private var currentHistoryId: String? = null

    init {
        // Seed default templates if needed
        viewModelScope.launch {
            repository.seedDefaultTemplatesIfNeeded()
        }
    }

    fun updatePromptText(text: String) {
        _uiState.update { it.copy(promptText = text) }
    }

    fun selectHistoryItem(item: PromptHistoryWithVersions) {
        _uiState.update { state ->
            state.copy(
                selectedHistoryId = item.history.id,
                promptText = item.history.prompt,
                generatedOutput = item.versions.lastOrNull()?.output ?: "",
                selectedVersionIndex = item.versions.lastIndex.coerceAtLeast(0),
                showDrawer = false
            )
        }
        currentHistoryId = item.history.id
    }

    fun selectVersion(index: Int) {
        val historyId = _uiState.value.selectedHistoryId ?: return
        viewModelScope.launch {
            repository.getHistoryById(historyId)?.let { item ->
                val version = item.versions.getOrNull(index)
                if (version != null) {
                    _uiState.update { state ->
                        state.copy(
                            generatedOutput = version.output,
                            selectedVersionIndex = index
                        )
                    }
                }
            }
        }
    }

    fun createNewPrompt() {
        _uiState.update { state ->
            state.copy(
                selectedHistoryId = null,
                promptText = "",
                generatedOutput = "",
                selectedVersionIndex = 0,
                showDrawer = false
            )
        }
        currentHistoryId = null
    }

    fun applyTemplate(template: CustomTemplateEntity) {
        _uiState.update { it.copy(promptText = template.content) }
    }

    fun toggleDrawer() {
        _uiState.update { it.copy(showDrawer = !it.showDrawer) }
    }

    fun generatePrompt(length: PromptLength) {
        val prompt = _uiState.value.promptText.trim()
        if (prompt.isEmpty()) {
            _uiState.update { it.copy(error = "Please enter a prompt first") }
            return
        }

        // Check API key before starting
        if (!apiKeyManager.hasApiKey) {
            _uiState.update { it.copy(error = "API key not configured. Please add your OpenAI API key in Settings.") }
            return
        }

        generationJob?.cancel()

        viewModelScope.launch {
            var historyId: String? = null
            try {
                // Find or create history item
                val existingItem = repository.findExistingPrompt(prompt)

                historyId = if (existingItem != null) {
                    existingItem.id
                } else {
                    val newHistory = PromptHistoryEntity(
                        prompt = prompt,
                        generationStatus = GenerationStatus.GENERATING.name
                    )
                    repository.insertHistory(newHistory)
                    newHistory.id
                }

                currentHistoryId = historyId
                _uiState.update { state ->
                    state.copy(
                        selectedHistoryId = historyId,
                        isGenerating = true,
                        error = null,
                        generatedOutput = ""
                    )
                }
                generatingIds.update { it + historyId }
                repository.updateHistoryStatus(historyId, GenerationStatus.GENERATING)

                val systemPrompt = when (length) {
                    PromptLength.SHORT -> SHORT_SYSTEM_PROMPT
                    PromptLength.LONG -> LONG_SYSTEM_PROMPT
                }

                var fullOutput = ""

                generationJob = viewModelScope.launch {
                    try {
                        promptService.generatePromptStream(prompt, systemPrompt).collect { event ->
                            when (event) {
                                is StreamEvent.Started -> {
                                    // Already handled above
                                }
                                is StreamEvent.Content -> {
                                    fullOutput += event.text
                                    _uiState.update { state ->
                                        state.copy(generatedOutput = fullOutput)
                                    }
                                }
                                is StreamEvent.Completed -> {
                                    // Save the version to database
                                    try {
                                        repository.addVersion(historyId, fullOutput)
                                    } catch (e: Exception) {
                                        Log.e(TAG, "Failed to save version to database", e)
                                    }
                                    _uiState.update { state ->
                                        state.copy(isGenerating = false)
                                    }
                                    generatingIds.update { it - historyId }
                                }
                                is StreamEvent.Error -> {
                                    Log.e(TAG, "Stream error: ${event.message}")
                                    try {
                                        repository.updateHistoryStatus(historyId, GenerationStatus.FAILED, event.message)
                                    } catch (e: Exception) {
                                        Log.e(TAG, "Failed to update history status", e)
                                    }
                                    _uiState.update { state ->
                                        state.copy(isGenerating = false, error = formatErrorMessage(event.message))
                                    }
                                    generatingIds.update { it - historyId }
                                }
                            }
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Generation error", e)
                        val errorMessage = formatErrorMessage(e)
                        try {
                            repository.updateHistoryStatus(historyId, GenerationStatus.FAILED, errorMessage)
                        } catch (dbError: Exception) {
                            Log.e(TAG, "Failed to update history status", dbError)
                        }
                        _uiState.update { state ->
                            state.copy(isGenerating = false, error = errorMessage)
                        }
                        generatingIds.update { it - historyId }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start generation", e)
                val errorMessage = formatErrorMessage(e)
                _uiState.update { state ->
                    state.copy(isGenerating = false, error = errorMessage)
                }
                historyId?.let { id ->
                    generatingIds.update { it - id }
                    try {
                        repository.updateHistoryStatus(id, GenerationStatus.FAILED, errorMessage)
                    } catch (dbError: Exception) {
                        Log.e(TAG, "Failed to update history status", dbError)
                    }
                }
            }
        }
    }

    private fun formatErrorMessage(e: Exception): String {
        return when (e) {
            is UnknownHostException -> "No internet connection. Please check your network."
            is SocketTimeoutException -> "Request timed out. Please try again."
            else -> e.message ?: "An unexpected error occurred"
        }
    }

    private fun formatErrorMessage(message: String?): String {
        return message ?: "An unexpected error occurred"
    }

    fun cancelGeneration() {
        generationJob?.cancel()
        generationJob = null
        currentHistoryId?.let { id ->
            viewModelScope.launch {
                repository.updateHistoryStatus(id, GenerationStatus.CANCELLED)
            }
            generatingIds.update { it - id }
        }
        _uiState.update { it.copy(isGenerating = false) }
    }

    fun archiveHistory(item: PromptHistoryWithVersions) {
        viewModelScope.launch {
            repository.archiveHistory(item.history.id)
            if (_uiState.value.selectedHistoryId == item.history.id) {
                createNewPrompt()
            }
        }
    }

    fun deleteHistory(item: PromptHistoryWithVersions) {
        viewModelScope.launch {
            repository.deleteHistory(item.history.id)
            if (_uiState.value.selectedHistoryId == item.history.id) {
                createNewPrompt()
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun setApiKey(key: String) {
        settingsRepository.updateApiKey(key)
        _uiState.update { it.copy(hasApiKey = settingsRepository.hasApiKey()) }
    }

    fun checkApiKey() {
        _uiState.update { it.copy(hasApiKey = settingsRepository.hasApiKey()) }
    }

    fun getSelectedHistoryVersions(): List<PromptVersionEntity> {
        val historyId = _uiState.value.selectedHistoryId ?: return emptyList()
        return history.value.find { it.history.id == historyId }?.versions ?: emptyList()
    }

    companion object {
        private const val TAG = "MainViewModel"

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
