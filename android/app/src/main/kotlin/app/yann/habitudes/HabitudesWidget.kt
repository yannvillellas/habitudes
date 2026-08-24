package app.yann.habitudes

import android.content.Context
import androidx.annotation.Keep
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.appwidget.CheckBox
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.state.getAppWidgetState
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

private val habitIdPrefKey = stringPreferencesKey("habit_id")

@Keep
class HabitudesWidget : GlanceAppWidget() {

    override suspend fun providePreview(context: Context, id: Int) {
        provideContent { widgetContent("Habitudes") }
    }

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val habitId = withContext(Dispatchers.IO) {
            try {
                val prefs = getAppWidgetState(context, PreferencesGlanceStateDefinition, id)
                prefs[habitIdPrefKey]
            } catch (_: Exception) {
                null
            }
        }

        val habitName = if (habitId != null) {
            withContext(Dispatchers.IO) { HabitudesDatabase(context).loadHabitName(habitId) }
        } else {
            null
        }

        provideContent {
            widgetContent(habitName ?: context.getString(R.string.no_habit))
        }
    }
}

@Keep
class HabitudesWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = HabitudesWidget()
}

@Composable
private fun widgetContent(text: String) {
    var checked by remember { mutableStateOf(false) }
    GlanceTheme {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(GlanceTheme.colors.widgetBackground),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            CheckBox(checked = checked, onCheckedChange = { checked = !checked })
            Text(text = text, style = TextStyle(color = GlanceTheme.colors.onSurface))
        }
    }
}
