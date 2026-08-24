package app.yann.habitudes

import android.appwidget.AppWidgetManager
import android.content.Context
import android.util.Log
import androidx.annotation.Keep
import androidx.compose.runtime.Composable
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.ExperimentalGlanceApi
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.AppWidgetId
import androidx.glance.appwidget.CheckBox
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.ToggleableStateKey
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.runComposition
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

private const val LOG_TAG = "HabitudesWidget"

@Keep
class HabitudesWidget : GlanceAppWidget() {

    override suspend fun providePreview(context: Context, id: Int) {
        provideContent { widgetContent("Habitudes", checked = false) }
    }

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = (id as? AppWidgetId)?.appWidgetId
        val database = HabitudesDatabase(context)
        val (habitName, checked) = withContext(Dispatchers.IO) {
            val habitId = appWidgetId?.let { database.getWidgetHabit(it) }
            val name = habitId?.let { database.loadHabitName(it) }
            val today = utcDateText(System.currentTimeMillis())
            val completedInDb = habitId?.let { database.isTodayCompleted(it, today) } ?: false
            name to completedInDb
        }

        provideContent {
            widgetContent(habitName ?: context.getString(R.string.no_habit), checked)
        }
    }
}

@Keep
@OptIn(ExperimentalGlanceApi::class)
class CheckInToggleAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        val newChecked = parameters[ToggleableStateKey]
        if (newChecked == null) {
            Log.w(LOG_TAG, "onAction: ToggleableStateKey missing")
            return
        }
        val appWidgetId = (glanceId as? AppWidgetId)?.appWidgetId
        if (appWidgetId == null) {
            Log.w(LOG_TAG, "onAction: unexpected glanceId type")
            return
        }
        val today = utcDateText(System.currentTimeMillis())
        val result = withContext(Dispatchers.IO) {
            val database = HabitudesDatabase(context)
            val habitId = database.getWidgetHabit(appWidgetId)
            if (habitId == null) {
                null
            } else {
                habitId to database.setTodayCompleted(habitId, newChecked, today)
            }
        }
        if (result == null) {
            Log.w(LOG_TAG, "onAction: no habit selected for appWidgetId=$appWidgetId")
            return
        }
        val (habitId, success) = result
        if (!success) {
            Log.e(LOG_TAG, "onAction: db write failed for habitId=$habitId newChecked=$newChecked")
            return
        }
        renderAllWidgets(context)
    }
}

@Keep
class HabitudesWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = HabitudesWidget()
}

private val renderMutex = Mutex()

@OptIn(ExperimentalGlanceApi::class)
suspend fun renderAllWidgets(context: Context) = renderMutex.withLock {
    val manager = GlanceAppWidgetManager(context)
    val appWidgetManager = AppWidgetManager.getInstance(context)
    val glanceIds = manager.getGlanceIds(HabitudesWidget::class.java)
    val appWidgetIds = glanceIds.mapNotNull { (it as? AppWidgetId)?.appWidgetId }

    // Widgets bound to the same habit render identical content: compose once
    // per habit and push the same RemoteViews to every instance in the group.
    val database = HabitudesDatabase(context)
    val idsByHabit = appWidgetIds.groupBy { database.getWidgetHabit(it) }
    for ((_, ids) in idsByHabit) {
        val glanceId = GlanceAppWidgetManager(context).getGlanceIdBy(ids.first())
        val remoteViews = HabitudesWidget().runComposition(context, glanceId).first()
        ids.forEach { appWidgetManager.updateAppWidget(it, remoteViews) }
    }
}

@Composable
private fun widgetContent(text: String, checked: Boolean) {
    GlanceTheme {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(GlanceTheme.colors.widgetBackground),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            CheckBox(
                checked = checked,
                onCheckedChange = actionRunCallback<CheckInToggleAction>(),
            )
            Text(text = text, style = TextStyle(color = GlanceTheme.colors.onSurface))
        }
    }
}
