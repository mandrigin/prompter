package com.prompter.db

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface PromptHistoryDao {

    @Transaction
    @Query("SELECT * FROM prompt_history WHERE isArchived = 0 ORDER BY timestamp DESC")
    fun getAllWithVersions(): Flow<List<PromptHistoryWithVersions>>

    @Transaction
    @Query("SELECT * FROM prompt_history WHERE isArchived = 1 ORDER BY timestamp DESC")
    fun getArchivedWithVersions(): Flow<List<PromptHistoryWithVersions>>

    @Transaction
    @Query("SELECT * FROM prompt_history WHERE id = :id")
    suspend fun getByIdWithVersions(id: String): PromptHistoryWithVersions?

    @Query("SELECT * FROM prompt_history WHERE prompt = :prompt AND isArchived = 0 LIMIT 1")
    suspend fun findByPrompt(prompt: String): PromptHistoryEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertHistory(history: PromptHistoryEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertVersion(version: PromptVersionEntity)

    @Update
    suspend fun updateHistory(history: PromptHistoryEntity)

    @Query("UPDATE prompt_history SET generationStatus = :status, errorMessage = :error WHERE id = :id")
    suspend fun updateStatus(id: String, status: String, error: String? = null)

    @Query("UPDATE prompt_history SET isArchived = :archived WHERE id = :id")
    suspend fun setArchived(id: String, archived: Boolean)

    @Query("UPDATE prompt_history SET isFavorite = :favorite WHERE id = :id")
    suspend fun setFavorite(id: String, favorite: Boolean)

    @Query("UPDATE prompt_history SET timestamp = :timestamp WHERE id = :id")
    suspend fun updateTimestamp(id: String, timestamp: Long)

    @Query("DELETE FROM prompt_history WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM prompt_history")
    suspend fun deleteAll()
}
