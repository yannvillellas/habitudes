package app.yann.habitudes

import android.appwidget.AppWidgetManager
import android.content.Context
import android.util.Log
import android.widget.RemoteViews
import androidx.annotation.Keep
import androidx.compose.runtime.Composable
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.ExperimentalGlanceApi
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
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

private val habitIdKey = ActionParameters.Key<String>(EXTRA_HABIT_ID)

@Keep
class HabitudesWidget : GlanceAppWidget() {

    override suspend fun providePreview(context: Context, id: Int) {
        provideContent {
            widgetContent(context.getString(R.string.habit_title), checked = false, habitId = null)
        }
    }

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = (id as? AppWidgetId)?.appWidgetId
        val database = HabitudesDatabase(context)
        val (habitName, checked, habitId) = withContext(Dispatchers.IO) {
            val habitId = appWidgetId?.let { database.getWidgetHabit(it) }
            val name = habitId?.let { database.loadHabitName(it) }
            val today = deviceDateText(System.currentTimeMillis())
            val completedInDb = habitId?.let { database.isTodayCompleted(it, today) } ?: false
            Triple(name, completedInDb, habitId)
        }

        provideContent {
            widgetContent(habitName ?: context.getString(R.string.no_habit), checked, habitId)
        }
    }
}

@Keep
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
        val today = deviceDateText(System.currentTimeMillis())
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

private val renderRetryDelaysMs = longArrayOf(500, 1000)

@OptIn(ExperimentalGlanceApi::class)
private suspend fun composeWithRetry(context: Context, glanceId: GlanceId): RemoteViews? {
    val remoteViews = retryOnIllegalState(renderRetryDelaysMs) {
        HabitudesWidget().runComposition(context, glanceId).first()
    }
    if (remoteViews == null) {
        Log.e(LOG_TAG, "runComposition failed after retries, glanceId=$glanceId")
    }
    return remoteViews
}

suspend fun renderAllWidgets(context: Context): Unit = renderMutex.withLock {
    try {
        val manager = GlanceAppWidgetManager(context)
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val glanceIds = manager.getGlanceIds(HabitudesWidget::class.java)
        val appWidgetIds = glanceIds.mapNotNull { (it as? AppWidgetId)?.appWidgetId }

        // Widgets bound to the same habit render identical content: compose once
        // per habit and push the same RemoteViews to every instance in the group.
        val database = HabitudesDatabase(context)
        val idsByHabit = appWidgetIds.groupBy { database.getWidgetHabit(it) }
        for ((_, ids) in idsByHabit) {
            val appWidgetId = ids.first()
            try {
                val glanceId = GlanceAppWidgetManager(context).getGlanceIdBy(appWidgetId)
                val remoteViews = composeWithRetry(context, glanceId) ?: continue
                ids.forEach { appWidgetManager.updateAppWidget(it, remoteViews) }
            } catch (e: Exception) {
                Log.e(LOG_TAG, "render failed for appWidgetId=$appWidgetId", e)
            }
        }
    } catch (e: Exception) {
        Log.e(LOG_TAG, "renderAllWidgets failed", e)
    }
}

suspend fun renderWidget(context: Context, appWidgetId: Int): Unit = renderMutex.withLock {
    try {
        val glanceId = GlanceAppWidgetManager(context).getGlanceIdBy(appWidgetId)
        val remoteViews = composeWithRetry(context, glanceId) ?: return@withLock
        AppWidgetManager.getInstance(context).updateAppWidget(appWidgetId, remoteViews)
    } catch (e: Exception) {
        Log.e(LOG_TAG, "render failed for appWidgetId=$appWidgetId", e)
    }
}

@Composable
private fun widgetContent(text: String, checked: Boolean, habitId: String?) {
    GlanceTheme {
        val baseModifier = GlanceModifier
            .fillMaxSize()
            .background(GlanceTheme.colors.widgetBackground)
        val columnModifier = if (habitId != null) {
            baseModifier.clickable(
                actionStartActivity<MainActivity>(
                    actionParametersOf(habitIdKey to habitId),
                ),
            )
        } else {
            baseModifier
        }
        Column(
            modifier = columnModifier,
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            CheckBox(
                checked = checked,
                onCheckedChange = actionRunCallback<CheckInToggleAction>(),
            )
            Text(
                text = text,
                style = TextStyle(color = GlanceTheme.colors.onSurface),
            )
        }
    }
}
