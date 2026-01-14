package com.prompter

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.prompter.ui.screens.MainScreen
import com.prompter.ui.theme.PrompterTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            PrompterTheme {
                MainScreen(
                    onNavigateToSettings = {
                        // TODO: Navigate to settings screen
                    }
                )
            }
        }
    }
}
