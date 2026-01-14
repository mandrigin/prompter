package com.prompter.db

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface CustomTemplateDao {

    @Query("SELECT * FROM custom_templates ORDER BY sortOrder ASC")
    fun getAll(): Flow<List<CustomTemplateEntity>>

    @Query("SELECT * FROM custom_templates WHERE id = :id")
    suspend fun getById(id: String): CustomTemplateEntity?

    @Query("SELECT * FROM custom_templates WHERE name = :name LIMIT 1")
    suspend fun findByName(name: String): CustomTemplateEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(template: CustomTemplateEntity)

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAll(templates: List<CustomTemplateEntity>)

    @Update
    suspend fun update(template: CustomTemplateEntity)

    @Query("DELETE FROM custom_templates WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("SELECT COUNT(*) FROM custom_templates")
    suspend fun count(): Int
}
