package com.prompter.data

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

data class Settings(
    val apiKey: String = "",
    val model: String = "gpt-4",
    val systemPromptShort: String = DEFAULT_SHORT_SYSTEM_PROMPT,
    val systemPromptLong: String = DEFAULT_LONG_SYSTEM_PROMPT,
    val isDarkTheme: Boolean = true
) {
    companion object {
        const val DEFAULT_SHORT_SYSTEM_PROMPT = """You are a prompt engineering expert. Your task is to transform the user's rough idea into a clear, effective prompt.

Rules:
- Be concise and direct
- Focus on the core objective
- Use clear, simple language
- Output ONLY the improved prompt, no explanations"""

        const val DEFAULT_LONG_SYSTEM_PROMPT = """You are a prompt engineering expert. Your task is to transform the user's rough idea into a comprehensive, detailed prompt.

Rules:
- Be thorough and detailed
- Include context, constraints, and examples where helpful
- Structure the prompt clearly with sections if needed
- Consider edge cases and clarify ambiguities
- Output ONLY the improved prompt, no explanations"""
    }
}

class SettingsRepository(context: Context) {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val sharedPreferences: SharedPreferences = EncryptedSharedPreferences.create(
        context,
        "prompter_secure_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    private val _settings = MutableStateFlow(loadSettings())
    val settings: StateFlow<Settings> = _settings.asStateFlow()

    private fun loadSettings(): Settings {
        return Settings(
            apiKey = sharedPreferences.getString(KEY_API_KEY, "") ?: "",
            model = sharedPreferences.getString(KEY_MODEL, "gpt-4") ?: "gpt-4",
            systemPromptShort = sharedPreferences.getString(KEY_SYSTEM_PROMPT_SHORT, Settings.DEFAULT_SHORT_SYSTEM_PROMPT)
                ?: Settings.DEFAULT_SHORT_SYSTEM_PROMPT,
            systemPromptLong = sharedPreferences.getString(KEY_SYSTEM_PROMPT_LONG, Settings.DEFAULT_LONG_SYSTEM_PROMPT)
                ?: Settings.DEFAULT_LONG_SYSTEM_PROMPT,
            isDarkTheme = sharedPreferences.getBoolean(KEY_DARK_THEME, true)
        )
    }

    fun updateApiKey(apiKey: String) {
        sharedPreferences.edit().putString(KEY_API_KEY, apiKey).apply()
        _settings.value = _settings.value.copy(apiKey = apiKey)
    }

    fun updateModel(model: String) {
        sharedPreferences.edit().putString(KEY_MODEL, model).apply()
        _settings.value = _settings.value.copy(model = model)
    }

    fun updateSystemPromptShort(prompt: String) {
        sharedPreferences.edit().putString(KEY_SYSTEM_PROMPT_SHORT, prompt).apply()
        _settings.value = _settings.value.copy(systemPromptShort = prompt)
    }

    fun updateSystemPromptLong(prompt: String) {
        sharedPreferences.edit().putString(KEY_SYSTEM_PROMPT_LONG, prompt).apply()
        _settings.value = _settings.value.copy(systemPromptLong = prompt)
    }

    fun updateDarkTheme(isDark: Boolean) {
        sharedPreferences.edit().putBoolean(KEY_DARK_THEME, isDark).apply()
        _settings.value = _settings.value.copy(isDarkTheme = isDark)
    }

    fun hasApiKey(): Boolean = _settings.value.apiKey.isNotBlank()

    companion object {
        private const val KEY_API_KEY = "api_key"
        private const val KEY_MODEL = "model"
        private const val KEY_SYSTEM_PROMPT_SHORT = "system_prompt_short"
        private const val KEY_SYSTEM_PROMPT_LONG = "system_prompt_long"
        private const val KEY_DARK_THEME = "dark_theme"

        val AVAILABLE_MODELS = listOf(
            "gpt-4" to "GPT-4",
            "gpt-4-turbo" to "GPT-4 Turbo",
            "gpt-4o" to "GPT-4o",
            "gpt-4o-mini" to "GPT-4o Mini",
            "gpt-3.5-turbo" to "GPT-3.5 Turbo"
        )
    }
}
