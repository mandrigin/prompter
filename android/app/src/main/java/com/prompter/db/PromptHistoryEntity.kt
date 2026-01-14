package com.prompter.db

import androidx.room.*
import java.util.Date
import java.util.UUID

@Entity(tableName = "prompt_history")
data class PromptHistoryEntity(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val prompt: String,
    val timestamp: Long = System.currentTimeMillis(),
    val isFavorite: Boolean = false,
    val isArchived: Boolean = false,
    val generationStatus: String = "pending",
    val errorMessage: String? = null
)

@Entity(
    tableName = "prompt_versions",
    foreignKeys = [
        ForeignKey(
            entity = PromptHistoryEntity::class,
            parentColumns = ["id"],
            childColumns = ["historyId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("historyId")]
)
data class PromptVersionEntity(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val historyId: String,
    val output: String,
    val timestamp: Long = System.currentTimeMillis()
)

data class PromptHistoryWithVersions(
    @Embedded val history: PromptHistoryEntity,
    @Relation(
        parentColumn = "id",
        entityColumn = "historyId"
    )
    val versions: List<PromptVersionEntity>
)

enum class GenerationStatus {
    PENDING,
    GENERATING,
    COMPLETED,
    FAILED,
    CANCELLED;

    companion object {
        fun fromString(value: String): GenerationStatus {
            return try {
                valueOf(value.uppercase())
            } catch (e: Exception) {
                PENDING
            }
        }
    }
}
