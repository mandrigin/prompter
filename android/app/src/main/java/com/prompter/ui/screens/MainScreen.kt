package com.prompter.ui.screens

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.prompter.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    viewModel: MainViewModel = viewModel(),
    onNavigateToSettings: () -> Unit = {}
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        "Prompter",
                        color = TextPrimary,
                        fontWeight = FontWeight.SemiBold
                    )
                },
                actions = {
                    IconButton(onClick = onNavigateToSettings) {
                        Icon(
                            Icons.Default.Settings,
                            contentDescription = "Settings",
                            tint = TextSecondary
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Background
                )
            )
        },
        containerColor = Background
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp)
        ) {
            // API Key Warning
            if (!uiState.hasApiKey) {
                ApiKeyWarning(onNavigateToSettings = onNavigateToSettings)
                Spacer(modifier = Modifier.height(16.dp))
            }

            // Show expanded input when no output, compact when output exists
            if (uiState.generatedOutput.isEmpty() && !uiState.isGenerating) {
                // Expanded input state
                PromptInputExpanded(
                    promptText = uiState.promptText,
                    onPromptChange = viewModel::updatePromptText,
                    onGenerateShort = { viewModel.generatePrompt(PromptLength.SHORT) },
                    onGenerateLong = { viewModel.generatePrompt(PromptLength.LONG) },
                    isEnabled = uiState.hasApiKey && uiState.promptText.isNotBlank(),
                    modifier = Modifier.weight(1f)
                )
            } else {
                // Compact input + output state
                PromptInputCompact(
                    promptText = uiState.promptText,
                    onPromptChange = viewModel::updatePromptText,
                    onGenerateShort = { viewModel.generatePrompt(PromptLength.SHORT) },
                    onGenerateLong = { viewModel.generatePrompt(PromptLength.LONG) },
                    isEnabled = uiState.hasApiKey && uiState.promptText.isNotBlank(),
                    isGenerating = uiState.isGenerating
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Output area
                OutputArea(
                    output = uiState.generatedOutput,
                    isGenerating = uiState.isGenerating,
                    onCopy = {
                        copyToClipboard(context, uiState.generatedOutput)
                    },
                    onCancel = viewModel::cancelGeneration,
                    modifier = Modifier.weight(1f)
                )
            }

            // Error snackbar
            uiState.error?.let { error ->
                Spacer(modifier = Modifier.height(8.dp))
                ErrorCard(
                    message = error,
                    onDismiss = viewModel::clearError
                )
            }
        }
    }
}

@Composable
private fun ApiKeyWarning(onNavigateToSettings: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = Warning.copy(alpha = 0.15f)),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "API key required",
                color = Warning,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.weight(1f)
            )
            TextButton(onClick = onNavigateToSettings) {
                Text("Configure", color = Warning)
            }
        }
    }
}

@Composable
private fun PromptInputExpanded(
    promptText: String,
    onPromptChange: (String) -> Unit,
    onGenerateShort: () -> Unit,
    onGenerateLong: () -> Unit,
    isEnabled: Boolean,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        OutlinedTextField(
            value = promptText,
            onValueChange = onPromptChange,
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f),
            placeholder = {
                Text(
                    "Describe what you want to accomplish...",
                    color = TextTertiary
                )
            },
            colors = OutlinedTextFieldDefaults.colors(
                focusedTextColor = TextPrimary,
                unfocusedTextColor = TextPrimary,
                focusedBorderColor = Accent,
                unfocusedBorderColor = Border,
                focusedContainerColor = Card,
                unfocusedContainerColor = Card,
                cursorColor = Accent
            ),
            shape = RoundedCornerShape(12.dp)
        )

        Spacer(modifier = Modifier.height(16.dp))

        GenerateButtons(
            onGenerateShort = onGenerateShort,
            onGenerateLong = onGenerateLong,
            isEnabled = isEnabled,
            isGenerating = false
        )
    }
}

@Composable
private fun PromptInputCompact(
    promptText: String,
    onPromptChange: (String) -> Unit,
    onGenerateShort: () -> Unit,
    onGenerateLong: () -> Unit,
    isEnabled: Boolean,
    isGenerating: Boolean
) {
    Column {
        OutlinedTextField(
            value = promptText,
            onValueChange = onPromptChange,
            modifier = Modifier
                .fillMaxWidth()
                .height(100.dp),
            placeholder = {
                Text("Enter prompt...", color = TextTertiary)
            },
            colors = OutlinedTextFieldDefaults.colors(
                focusedTextColor = TextPrimary,
                unfocusedTextColor = TextPrimary,
                focusedBorderColor = Accent,
                unfocusedBorderColor = Border,
                focusedContainerColor = Card,
                unfocusedContainerColor = Card,
                cursorColor = Accent
            ),
            shape = RoundedCornerShape(12.dp)
        )

        Spacer(modifier = Modifier.height(12.dp))

        GenerateButtons(
            onGenerateShort = onGenerateShort,
            onGenerateLong = onGenerateLong,
            isEnabled = isEnabled,
            isGenerating = isGenerating
        )
    }
}

@Composable
private fun GenerateButtons(
    onGenerateShort: () -> Unit,
    onGenerateLong: () -> Unit,
    isEnabled: Boolean,
    isGenerating: Boolean
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Short button
        OutlinedButton(
            onClick = onGenerateShort,
            enabled = isEnabled && !isGenerating,
            modifier = Modifier.weight(1f),
            colors = ButtonDefaults.outlinedButtonColors(
                contentColor = Accent
            ),
            border = ButtonDefaults.outlinedButtonBorder(enabled = isEnabled).copy(
                brush = androidx.compose.ui.graphics.SolidColor(
                    if (isEnabled) Accent.copy(alpha = 0.5f) else Border
                )
            ),
            shape = RoundedCornerShape(8.dp)
        ) {
            Text("⚡ Short")
        }

        // Long button
        Button(
            onClick = onGenerateLong,
            enabled = isEnabled && !isGenerating,
            modifier = Modifier.weight(1f),
            colors = ButtonDefaults.buttonColors(
                containerColor = Accent,
                contentColor = TextPrimary
            ),
            shape = RoundedCornerShape(8.dp)
        ) {
            if (isGenerating) {
                CircularProgressIndicator(
                    modifier = Modifier.size(16.dp),
                    color = TextPrimary,
                    strokeWidth = 2.dp
                )
                Spacer(modifier = Modifier.width(8.dp))
            }
            Text("✨ Long")
        }
    }
}

@Composable
private fun OutputArea(
    output: String,
    isGenerating: Boolean,
    onCopy: () -> Unit,
    onCancel: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(Accent.copy(alpha = 0.08f))
            .border(1.dp, Accent.copy(alpha = 0.2f), RoundedCornerShape(12.dp))
            .padding(16.dp)
    ) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                "Generated Prompt",
                color = TextPrimary,
                fontWeight = FontWeight.Medium,
                fontSize = 14.sp
            )

            if (output.isNotEmpty()) {
                IconButton(onClick = onCopy) {
                    Icon(
                        Icons.Default.ContentCopy,
                        contentDescription = "Copy",
                        tint = Accent,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Content
        Box(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .clip(RoundedCornerShape(8.dp))
                .background(Surface)
                .border(1.dp, Accent.copy(alpha = 0.3f), RoundedCornerShape(8.dp))
        ) {
            if (isGenerating && output.isEmpty()) {
                // Loading state
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    CircularProgressIndicator(
                        color = Accent,
                        modifier = Modifier.size(32.dp)
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        "Generating improved prompt...",
                        color = TextSecondary
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    TextButton(onClick = onCancel) {
                        Text("Cancel", color = TextTertiary)
                    }
                }
            } else {
                // Output content
                SelectionContainer {
                    Text(
                        text = output,
                        color = TextPrimary,
                        modifier = Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState())
                            .padding(12.dp),
                        lineHeight = 22.sp
                    )
                }

                // Streaming indicator
                AnimatedVisibility(
                    visible = isGenerating,
                    enter = fadeIn(),
                    exit = fadeOut(),
                    modifier = Modifier.align(Alignment.BottomEnd)
                ) {
                    CircularProgressIndicator(
                        modifier = Modifier
                            .padding(8.dp)
                            .size(16.dp),
                        color = Accent,
                        strokeWidth = 2.dp
                    )
                }
            }
        }
    }
}

@Composable
private fun ErrorCard(
    message: String,
    onDismiss: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = Error.copy(alpha = 0.15f)),
        shape = RoundedCornerShape(8.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = message,
                color = Error,
                modifier = Modifier.weight(1f),
                fontSize = 13.sp
            )
            TextButton(onClick = onDismiss) {
                Text("Dismiss", color = Error)
            }
        }
    }
}

private fun copyToClipboard(context: Context, text: String) {
    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    val clip = ClipData.newPlainText("Generated Prompt", text)
    clipboard.setPrimaryClip(clip)
    Toast.makeText(context, "Copied to clipboard", Toast.LENGTH_SHORT).show()
}
