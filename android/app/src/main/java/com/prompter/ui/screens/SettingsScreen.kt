package com.prompter.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import com.prompter.data.AIProvider
import com.prompter.data.Settings
import com.prompter.data.SettingsRepository
import com.prompter.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    settings: Settings,
    onProviderChange: (AIProvider) -> Unit,
    onOpenaiApiKeyChange: (String) -> Unit,
    onClaudeApiKeyChange: (String) -> Unit,
    onModelChange: (String) -> Unit,
    onSystemPromptShortChange: (String) -> Unit,
    onSystemPromptLongChange: (String) -> Unit,
    onDarkThemeChange: (Boolean) -> Unit,
    onNavigateBack: () -> Unit
) {
    val scrollState = rememberScrollState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settings", color = TextPrimary) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back",
                            tint = TextPrimary
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
                .verticalScroll(scrollState)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // API Configuration Section
            SettingsSection(title = "API Configuration") {
                ProviderSelector(
                    selectedProvider = settings.provider,
                    onProviderChange = onProviderChange
                )
                Spacer(modifier = Modifier.height(16.dp))
                ApiKeyInput(
                    label = "OpenAI API Key",
                    apiKey = settings.openaiApiKey,
                    placeholder = "sk-...",
                    onApiKeyChange = onOpenaiApiKeyChange,
                    isActive = settings.provider == AIProvider.OPENAI
                )
                Spacer(modifier = Modifier.height(16.dp))
                ApiKeyInput(
                    label = "Claude API Key",
                    apiKey = settings.claudeApiKey,
                    placeholder = "sk-ant-...",
                    onApiKeyChange = onClaudeApiKeyChange,
                    isActive = settings.provider == AIProvider.CLAUDE
                )
                Spacer(modifier = Modifier.height(16.dp))
                ModelSelector(
                    selectedModel = settings.model,
                    provider = settings.provider,
                    onModelChange = onModelChange
                )
            }

            // System Prompts Section
            SettingsSection(title = "System Prompts") {
                SystemPromptInput(
                    label = "Short Prompt",
                    value = settings.systemPromptShort,
                    onValueChange = onSystemPromptShortChange,
                    description = "Used for concise prompt generation"
                )
                Spacer(modifier = Modifier.height(16.dp))
                SystemPromptInput(
                    label = "Long Prompt",
                    value = settings.systemPromptLong,
                    onValueChange = onSystemPromptLongChange,
                    description = "Used for detailed prompt generation"
                )
            }

            // Appearance Section
            SettingsSection(title = "Appearance") {
                ThemeToggle(
                    isDarkTheme = settings.isDarkTheme,
                    onThemeChange = onDarkThemeChange
                )
            }

            // App Info Section
            SettingsSection(title = "About") {
                SettingsInfoRow(label = "Version", value = "1.0.0")
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
private fun SettingsSection(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Column {
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            color = Accent,
            modifier = Modifier.padding(bottom = 12.dp)
        )
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Surface)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                content = content
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ProviderSelector(
    selectedProvider: AIProvider,
    onProviderChange: (AIProvider) -> Unit
) {
    Column {
        Text(
            text = "AI Provider",
            style = MaterialTheme.typography.bodyMedium,
            color = TextSecondary,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            AIProvider.entries.forEach { provider ->
                FilterChip(
                    selected = selectedProvider == provider,
                    onClick = { onProviderChange(provider) },
                    label = {
                        Text(
                            when (provider) {
                                AIProvider.OPENAI -> "OpenAI"
                                AIProvider.CLAUDE -> "Claude"
                            }
                        )
                    },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = Accent,
                        selectedLabelColor = TextPrimary,
                        containerColor = Card,
                        labelColor = TextSecondary
                    ),
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun ApiKeyInput(
    label: String,
    apiKey: String,
    placeholder: String,
    onApiKeyChange: (String) -> Unit,
    isActive: Boolean
) {
    var isVisible by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier.alpha(if (isActive) 1f else 0.5f)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(bottom = 8.dp)
        ) {
            Text(
                text = label,
                style = MaterialTheme.typography.bodyMedium,
                color = TextSecondary
            )
            if (isActive) {
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "(Active)",
                    style = MaterialTheme.typography.bodySmall,
                    color = Accent
                )
            }
        }
        OutlinedTextField(
            value = apiKey,
            onValueChange = onApiKeyChange,
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text(placeholder, color = TextTertiary) },
            visualTransformation = if (isVisible) VisualTransformation.None else PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
            trailingIcon = {
                IconButton(onClick = { isVisible = !isVisible }) {
                    Icon(
                        imageVector = if (isVisible) Icons.Filled.Visibility else Icons.Filled.VisibilityOff,
                        contentDescription = if (isVisible) "Hide API key" else "Show API key",
                        tint = TextSecondary
                    )
                }
            },
            colors = OutlinedTextFieldDefaults.colors(
                focusedTextColor = TextPrimary,
                unfocusedTextColor = TextPrimary,
                focusedBorderColor = Accent,
                unfocusedBorderColor = Border,
                cursorColor = Accent,
                focusedContainerColor = Card,
                unfocusedContainerColor = Card
            ),
            shape = RoundedCornerShape(12.dp),
            singleLine = true
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ModelSelector(
    selectedModel: String,
    provider: AIProvider,
    onModelChange: (String) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    val availableModels = when (provider) {
        AIProvider.OPENAI -> SettingsRepository.OPENAI_MODELS
        AIProvider.CLAUDE -> SettingsRepository.CLAUDE_MODELS
    }
    val selectedModelName = availableModels
        .find { it.first == selectedModel }?.second ?: selectedModel

    Column {
        Text(
            text = "Model",
            style = MaterialTheme.typography.bodyMedium,
            color = TextSecondary,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        ExposedDropdownMenuBox(
            expanded = expanded,
            onExpandedChange = { expanded = !expanded }
        ) {
            OutlinedTextField(
                value = selectedModelName,
                onValueChange = {},
                readOnly = true,
                modifier = Modifier
                    .fillMaxWidth()
                    .menuAnchor(),
                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = TextPrimary,
                    unfocusedTextColor = TextPrimary,
                    focusedBorderColor = Accent,
                    unfocusedBorderColor = Border,
                    focusedContainerColor = Card,
                    unfocusedContainerColor = Card
                ),
                shape = RoundedCornerShape(12.dp)
            )
            ExposedDropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false },
                modifier = Modifier.background(Elevated)
            ) {
                availableModels.forEach { (modelId, modelName) ->
                    DropdownMenuItem(
                        text = { Text(modelName, color = TextPrimary) },
                        onClick = {
                            onModelChange(modelId)
                            expanded = false
                        },
                        colors = MenuDefaults.itemColors(
                            textColor = TextPrimary
                        ),
                        modifier = Modifier.background(
                            if (modelId == selectedModel) Accent.copy(alpha = 0.2f) else Elevated
                        )
                    )
                }
            }
        }
    }
}

@Composable
private fun SystemPromptInput(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    description: String
) {
    Column {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = TextSecondary,
            modifier = Modifier.padding(bottom = 4.dp)
        )
        Text(
            text = description,
            style = MaterialTheme.typography.bodySmall,
            color = TextTertiary,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 120.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedTextColor = TextPrimary,
                unfocusedTextColor = TextPrimary,
                focusedBorderColor = Accent,
                unfocusedBorderColor = Border,
                cursorColor = Accent,
                focusedContainerColor = Card,
                unfocusedContainerColor = Card
            ),
            shape = RoundedCornerShape(12.dp),
            maxLines = 8
        )
    }
}

@Composable
private fun ThemeToggle(
    isDarkTheme: Boolean,
    onThemeChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .clickable { onThemeChange(!isDarkTheme) }
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column {
            Text(
                text = "Dark Theme",
                style = MaterialTheme.typography.bodyMedium,
                color = TextPrimary
            )
            Text(
                text = if (isDarkTheme) "Nothing OS dark mode" else "Light mode",
                style = MaterialTheme.typography.bodySmall,
                color = TextTertiary
            )
        }
        Switch(
            checked = isDarkTheme,
            onCheckedChange = onThemeChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = TextPrimary,
                checkedTrackColor = Accent,
                uncheckedThumbColor = TextSecondary,
                uncheckedTrackColor = Border
            )
        )
    }
}

@Composable
private fun SettingsInfoRow(
    label: String,
    value: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = TextPrimary
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            color = TextSecondary
        )
    }
}
