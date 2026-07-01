package app.yann.habitudes

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import androidx.annotation.Keep
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@Keep
class HabitudesWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val habitName = withContext(Dispatchers.IO) {
            val allIds = GlanceAppWidgetManager(context).getGlanceIds(HabitudesWidget::class.java)
                .sortedBy { it.toString() }
            val index = allIds.indexOf(id)
            loadHabitNameAtIndex(context, if (index >= 0) index else 0)
        }

        provideContent {
            GlanceTheme {
                Column(
                    modifier = GlanceModifier
                        .fillMaxSize()
                        .background(GlanceTheme.colors.widgetBackground),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = habitName ?: "Habitudes",
                        style = TextStyle(color = GlanceTheme.colors.onSurface),
                    )
                }
            }
        }
    }
}

@Keep
class HabitudesWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = HabitudesWidget()
}

private fun loadHabitNameAtIndex(context: Context, index: Int): String? {
    val db = try {
        val dbPath = context.getDatabasePath("habitudes.db").absolutePath
        SQLiteDatabase.openDatabase(dbPath, null, SQLiteDatabase.OPEN_READONLY)
    } catch (e: Exception) {
        return null
    }
    return try {
        val names = mutableListOf<String>()
        val cursor = db.rawQuery("SELECT name FROM habits ORDER BY sort_order ASC", null)
        while (cursor.moveToNext()) {
            names.add(cursor.getString(0))
        }
        cursor.close()
        if (names.isEmpty()) null else names[index % names.size]
    } catch (e: Exception) {
        null
    } finally {
        db.close()
    }
}
