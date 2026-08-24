package app.yann.habitudes

import android.content.ContentValues
import android.content.Context
import android.database.DatabaseErrorHandler
import android.database.sqlite.SQLiteDatabase

// Schema is owned by lib/data/repositories/habit_repository_sqflite.dart.
// Keep table and column names in sync with that file.
object HabitudesDb {
    const val DATABASE_NAME = "habitudes.db"
    const val HABITS_TABLE = "habits"
    const val COMPLETIONS_TABLE = "habit_completions"
    const val ID_COLUMN = "id"
    const val NAME_COLUMN = "name"
    const val SORT_ORDER_COLUMN = "sort_order"
    const val HABIT_ID_COLUMN = "habit_id"
    const val DATE_COLUMN = "date"

    // Kotlin-owned table, created lazily (not part of the Dart schema in
    // lib/data/repositories/habit_repository_sqflite.dart).
    const val WIDGET_INSTANCES_TABLE = "widget_instances"
    const val APPWIDGET_ID_COLUMN = "appwidget_id"
}

data class HabitItem(val id: String, val name: String)

class HabitudesDatabase(private val context: Context) {

    fun loadHabits(): List<HabitItem> {
        val db = openDatabase(readOnly = true) ?: return emptyList()
        return try {
            buildList {
                db.rawQuery(
                    "SELECT ${HabitudesDb.ID_COLUMN}, ${HabitudesDb.NAME_COLUMN} " +
                        "FROM ${HabitudesDb.HABITS_TABLE} ORDER BY ${HabitudesDb.SORT_ORDER_COLUMN} ASC",
                    null,
                ).use { cursor ->
                    while (cursor.moveToNext()) {
                        add(HabitItem(cursor.getString(0), cursor.getString(1)))
                    }
                }
            }
        } catch (_: Exception) {
            emptyList()
        } finally {
            db.close()
        }
    }

    fun loadHabitName(habitId: String): String? {
        val db = openDatabase(readOnly = true) ?: return null
        return try {
            db.rawQuery(
                "SELECT ${HabitudesDb.NAME_COLUMN} FROM ${HabitudesDb.HABITS_TABLE} " +
                    "WHERE ${HabitudesDb.ID_COLUMN} = ?",
                arrayOf(habitId),
            ).use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
        } catch (_: Exception) {
            null
        } finally {
            db.close()
        }
    }

    fun isTodayCompleted(habitId: String, dateText: String): Boolean {
        val db = openDatabase(readOnly = true) ?: return false
        return try {
            db.rawQuery(
                "SELECT COUNT(*) FROM ${HabitudesDb.COMPLETIONS_TABLE} " +
                    "WHERE ${HabitudesDb.HABIT_ID_COLUMN} = ? AND ${HabitudesDb.DATE_COLUMN} = ?",
                arrayOf(habitId, dateText),
            ).use { cursor -> cursor.moveToFirst() && cursor.getInt(0) > 0 }
        } catch (_: Exception) {
            false
        } finally {
            db.close()
        }
    }

    fun setTodayCompleted(habitId: String, completed: Boolean, dateText: String): Boolean {
        val db = openDatabase(readOnly = false) ?: return false
        return try {
            if (completed) {
                db.insertWithOnConflict(
                    HabitudesDb.COMPLETIONS_TABLE,
                    null,
                    ContentValues().apply {
                        put(HabitudesDb.HABIT_ID_COLUMN, habitId)
                        put(HabitudesDb.DATE_COLUMN, dateText)
                    },
                    SQLiteDatabase.CONFLICT_IGNORE,
                )
            } else {
                db.delete(
                    HabitudesDb.COMPLETIONS_TABLE,
                    "${HabitudesDb.HABIT_ID_COLUMN} = ? AND ${HabitudesDb.DATE_COLUMN} = ?",
                    arrayOf(habitId, dateText),
                )
            }
            true
        } catch (_: Exception) {
            false
        } finally {
            db.close()
        }
    }

    fun getWidgetHabit(appWidgetId: Int): String? {
        val db = openDatabase(readOnly = true) ?: return null
        return try {
            db.rawQuery(
                "SELECT ${HabitudesDb.HABIT_ID_COLUMN} FROM ${HabitudesDb.WIDGET_INSTANCES_TABLE} " +
                    "WHERE ${HabitudesDb.APPWIDGET_ID_COLUMN} = ?",
                arrayOf(appWidgetId.toString()),
            ).use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
        } catch (_: Exception) {
            null
        } finally {
            db.close()
        }
    }

    fun setWidgetHabit(appWidgetId: Int, habitId: String): Boolean {
        val db = openDatabase(readOnly = false) ?: return false
        return try {
            db.insertWithOnConflict(
                HabitudesDb.WIDGET_INSTANCES_TABLE,
                null,
                ContentValues().apply {
                    put(HabitudesDb.APPWIDGET_ID_COLUMN, appWidgetId)
                    put(HabitudesDb.HABIT_ID_COLUMN, habitId)
                },
                SQLiteDatabase.CONFLICT_REPLACE,
            )
            true
        } catch (_: Exception) {
            false
        } finally {
            db.close()
        }
    }

    private fun openDatabase(readOnly: Boolean): SQLiteDatabase? {
        val path = context.getDatabasePath(HabitudesDb.DATABASE_NAME).absolutePath
        val flags = if (readOnly) SQLiteDatabase.OPEN_READONLY else SQLiteDatabase.OPEN_READWRITE
        return try {
            SQLiteDatabase.openDatabase(path, null, flags, NoOpErrorHandler).also { db ->
                runCatching { db.execSQL("PRAGMA busy_timeout = 3000") }
                if (!readOnly) {
                    runCatching { db.enableWriteAheadLogging() }
                    runCatching {
                        db.execSQL(
                            "CREATE TABLE IF NOT EXISTS ${HabitudesDb.WIDGET_INSTANCES_TABLE} (" +
                                "${HabitudesDb.APPWIDGET_ID_COLUMN} INTEGER PRIMARY KEY, " +
                                "${HabitudesDb.HABIT_ID_COLUMN} TEXT NOT NULL)",
                        )
                    }
                }
            }
        } catch (_: Exception) {
            null
        }
    }

    private object NoOpErrorHandler : DatabaseErrorHandler {
        override fun onCorruption(dbObj: SQLiteDatabase) = Unit
    }
}
