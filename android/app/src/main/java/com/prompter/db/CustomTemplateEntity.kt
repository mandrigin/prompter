package com.prompter.db

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(tableName = "custom_templates")
data class CustomTemplateEntity(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val content: String,
    val isDefault: Boolean = false,
    val sortOrder: Int = 0
)

object DefaultTemplates {
    val templates = listOf(
        TemplateData("Code Review", "Review this code for best practices, potential bugs, and improvements:"),
        TemplateData("Explain Code", "Explain what this code does in clear, simple terms:"),
        TemplateData("Debug Help", "Help me debug this issue:"),
        TemplateData("Quick Fix", "Fix this code with minimal changes:"),
        TemplateData("Refactor", "Refactor this to be more concise and readable:"),
        TemplateData("Architecture", "Suggest architectural improvements for:"),
        TemplateData("Best Practices", "What are the best practices for:"),
        TemplateData("Write Tests", "Write unit tests for this code:"),
        TemplateData("Business Research", "Research and analyze the following business topic, including market trends, competitors, and strategic insights:"),
        TemplateData("Technical Research", "Research the following technical topic, including documentation, implementation patterns, and best practices:")
    )

    fun createDefaults(): List<CustomTemplateEntity> {
        return templates.mapIndexed { index, template ->
            CustomTemplateEntity(
                name = template.name,
                content = template.content,
                isDefault = true,
                sortOrder = index
            )
        }
    }
}

data class TemplateData(
    val name: String,
    val content: String
)
