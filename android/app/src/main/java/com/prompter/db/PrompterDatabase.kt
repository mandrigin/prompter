package com.prompter.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.sqlite.db.SupportSQLiteDatabase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

@Database(
    entities = [
        PromptHistoryEntity::class,
        PromptVersionEntity::class,
        CustomTemplateEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class PrompterDatabase : RoomDatabase() {

    abstract fun promptHistoryDao(): PromptHistoryDao
    abstract fun customTemplateDao(): CustomTemplateDao

    companion object {
        @Volatile
        private var INSTANCE: PrompterDatabase? = null

        fun getDatabase(context: Context): PrompterDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    PrompterDatabase::class.java,
                    "prompter_database"
                )
                    .addCallback(DatabaseCallback())
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }

    private class DatabaseCallback : Callback() {
        override fun onCreate(db: SupportSQLiteDatabase) {
            super.onCreate(db)
            INSTANCE?.let { database ->
                CoroutineScope(Dispatchers.IO).launch {
                    seedDefaultTemplates(database.customTemplateDao())
                }
            }
        }

        private suspend fun seedDefaultTemplates(dao: CustomTemplateDao) {
            if (dao.count() == 0) {
                dao.insertAll(DefaultTemplates.createDefaults())
            }
        }
    }
}
