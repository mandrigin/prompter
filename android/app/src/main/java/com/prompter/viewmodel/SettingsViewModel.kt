package com.prompter.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import com.prompter.data.Settings
import com.prompter.data.SettingsRepository
import kotlinx.coroutines.flow.StateFlow

class SettingsViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = SettingsRepository(application)

    val settings: StateFlow<Settings> = repository.settings

    fun updateApiKey(apiKey: String) {
        repository.updateApiKey(apiKey)
    }

    fun updateModel(model: String) {
        repository.updateModel(model)
    }

    fun updateSystemPromptShort(prompt: String) {
        repository.updateSystemPromptShort(prompt)
    }

    fun updateSystemPromptLong(prompt: String) {
        repository.updateSystemPromptLong(prompt)
    }

    fun updateDarkTheme(isDark: Boolean) {
        repository.updateDarkTheme(isDark)
    }

    fun hasApiKey(): Boolean = repository.hasApiKey()
}
