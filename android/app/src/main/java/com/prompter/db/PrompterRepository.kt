package com.prompter.db

import kotlinx.coroutines.flow.Flow

class PrompterRepository(
    private val historyDao: PromptHistoryDao,
    private val templateDao: CustomTemplateDao
) {
    // History operations
    val allHistory: Flow<List<PromptHistoryWithVersions>> = historyDao.getAllWithVersions()
    val archivedHistory: Flow<List<PromptHistoryWithVersions>> = historyDao.getArchivedWithVersions()

    suspend fun getHistoryById(id: String): PromptHistoryWithVersions? {
        return historyDao.getByIdWithVersions(id)
    }

    suspend fun findExistingPrompt(prompt: String): PromptHistoryEntity? {
        return historyDao.findByPrompt(prompt.trim())
    }

    suspend fun insertHistory(history: PromptHistoryEntity) {
        historyDao.insertHistory(history)
    }

    suspend fun addVersion(historyId: String, output: String) {
        val version = PromptVersionEntity(
            historyId = historyId,
            output = output
        )
        historyDao.insertVersion(version)
        historyDao.updateTimestamp(historyId, System.currentTimeMillis())
        historyDao.updateStatus(historyId, GenerationStatus.COMPLETED.name)
    }

    suspend fun updateHistoryStatus(id: String, status: GenerationStatus, error: String? = null) {
        historyDao.updateStatus(id, status.name, error)
    }

    suspend fun archiveHistory(id: String) {
        historyDao.setArchived(id, true)
    }

    suspend fun unarchiveHistory(id: String) {
        historyDao.setArchived(id, false)
    }

    suspend fun toggleFavorite(id: String, favorite: Boolean) {
        historyDao.setFavorite(id, favorite)
    }

    suspend fun deleteHistory(id: String) {
        historyDao.deleteById(id)
    }

    suspend fun clearAllHistory() {
        historyDao.deleteAll()
    }

    // Template operations
    val allTemplates: Flow<List<CustomTemplateEntity>> = templateDao.getAll()

    suspend fun getTemplateById(id: String): CustomTemplateEntity? {
        return templateDao.getById(id)
    }

    suspend fun insertTemplate(template: CustomTemplateEntity) {
        templateDao.insert(template)
    }

    suspend fun updateTemplate(template: CustomTemplateEntity) {
        templateDao.update(template)
    }

    suspend fun deleteTemplate(id: String) {
        templateDao.deleteById(id)
    }

    suspend fun seedDefaultTemplatesIfNeeded() {
        val existingTemplates = templateDao.count()
        if (existingTemplates == 0) {
            templateDao.insertAll(DefaultTemplates.createDefaults())
        } else {
            // Add any missing default templates
            for (default in DefaultTemplates.templates) {
                if (templateDao.findByName(default.name) == null) {
                    val maxOrder = existingTemplates
                    templateDao.insert(
                        CustomTemplateEntity(
                            name = default.name,
                            content = default.content,
                            isDefault = true,
                            sortOrder = maxOrder
                        )
                    )
                }
            }
        }
    }
}
