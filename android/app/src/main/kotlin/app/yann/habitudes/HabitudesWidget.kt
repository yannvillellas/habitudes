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
            Log.d(
                LOG_TAG,
                "provideGlance: appWidgetId=$appWidgetId habitId=$habitId today=$today " +
                    "db=$completedInDb -> checked=$completedInDb",
            )
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
        Log.d(LOG_TAG, "onAction: fired, glanceId=$glanceId")
        val newChecked = parameters[ToggleableStateKey]
        if (newChecked == null) {
            Log.w(LOG_TAG, "onAction: ToggleableStateKey missing")
            return
        }
        Log.d(LOG_TAG, "onAction: newChecked=$newChecked")
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
        Log.d(LOG_TAG, "onAction: db write habitId=$habitId newChecked=$newChecked success=$success")
        if (!success) {
            return
        }
        val remoteViews = HabitudesWidget().runComposition(
            context = context,
            id = glanceId,
        ).first()
        AppWidgetManager.getInstance(context).updateAppWidget(appWidgetId, remoteViews)
        Log.d(LOG_TAG, "onAction: render pushed")
    }
}

@Keep
class HabitudesWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = HabitudesWidget()
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
