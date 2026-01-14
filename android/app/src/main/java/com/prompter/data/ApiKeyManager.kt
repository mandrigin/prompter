package com.prompter.data

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

class ApiKeyManager(context: Context) {

    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val encryptedPrefs: SharedPreferences = EncryptedSharedPreferences.create(
        context,
        PREFS_FILE_NAME,
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    var apiKey: String?
        get() = encryptedPrefs.getString(KEY_API_KEY, null)
        set(value) {
            encryptedPrefs.edit().apply {
                if (value != null) {
                    putString(KEY_API_KEY, value)
                } else {
                    remove(KEY_API_KEY)
                }
                apply()
            }
        }

    var model: String
        get() = encryptedPrefs.getString(KEY_MODEL, DEFAULT_MODEL) ?: DEFAULT_MODEL
        set(value) {
            encryptedPrefs.edit().putString(KEY_MODEL, value).apply()
        }

    val hasApiKey: Boolean
        get() = !apiKey.isNullOrBlank()

    fun clearApiKey() {
        apiKey = null
    }

    companion object {
        private const val PREFS_FILE_NAME = "prompter_secure_prefs"
        // Use same key names as SettingsRepository for consistency
        private const val KEY_API_KEY = "api_key"
        private const val KEY_MODEL = "model"
        const val DEFAULT_MODEL = "gpt-4"

        val AVAILABLE_MODELS = listOf(
            "gpt-4o",
            "gpt-4o-mini",
            "gpt-4-turbo",
            "gpt-4",
            "gpt-3.5-turbo"
        )
    }
}
