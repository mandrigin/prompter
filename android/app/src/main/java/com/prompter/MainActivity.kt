package com.prompter

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.prompter.data.SettingsRepository
import com.prompter.ui.screens.MainScreen
import com.prompter.ui.screens.SettingsScreen
import com.prompter.ui.theme.PrompterTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            val navController = rememberNavController()
            val settingsRepository = remember { SettingsRepository(this) }
            val settings by settingsRepository.settings.collectAsState()

            PrompterTheme {
                NavHost(
                    navController = navController,
                    startDestination = "main"
                ) {
                    composable("main") {
                        MainScreen(
                            onNavigateToSettings = {
                                navController.navigate("settings")
                            }
                        )
                    }
                    composable("settings") {
                        SettingsScreen(
                            settings = settings,
                            onProviderChange = settingsRepository::updateProvider,
                            onOpenaiApiKeyChange = settingsRepository::updateOpenaiApiKey,
                            onClaudeApiKeyChange = settingsRepository::updateClaudeApiKey,
                            onModelChange = settingsRepository::updateModel,
                            onSystemPromptShortChange = settingsRepository::updateSystemPromptShort,
                            onSystemPromptLongChange = settingsRepository::updateSystemPromptLong,
                            onDarkThemeChange = settingsRepository::updateDarkTheme,
                            onNavigateBack = { navController.popBackStack() }
                        )
                    }
                }
            }
        }
    }
}
