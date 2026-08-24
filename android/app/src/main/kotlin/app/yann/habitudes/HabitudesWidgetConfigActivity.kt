package app.yann.habitudes

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.annotation.Keep
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.glance.ExperimentalGlanceApi
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.runComposition
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

@OptIn(ExperimentalGlanceApi::class)
@Keep
class HabitudesWidgetConfigActivity : ComponentActivity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        val resultValue = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(RESULT_CANCELED, resultValue)

        val habits = HabitudesDatabase(this@HabitudesWidgetConfigActivity).loadHabits()

        val currentHabitId = HabitudesDatabase(this@HabitudesWidgetConfigActivity)
            .getWidgetHabit(appWidgetId)

        setContent {
            val colorScheme = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (resources.configuration.isNightModeActive) {
                    dynamicDarkColorScheme(this@HabitudesWidgetConfigActivity)
                } else {
                    dynamicLightColorScheme(this@HabitudesWidgetConfigActivity)
                }
            } else {
                if (resources.configuration.isNightModeActive) {
                    darkColorScheme()
                } else {
                    lightColorScheme()
                }
            }

            MaterialTheme(colorScheme = colorScheme) {
                if (habits.isEmpty()) {
                    EmptyHabitsDialog(onDismiss = { finish() })
                } else {
                    var selectedId by remember { mutableStateOf(currentHabitId) }
                    HabitPickerDialog(
                        habits = habits,
                        selectedId = selectedId,
                        onSelectionChanged = { selectedId = it },
                        onConfirm = { selectedId?.let { id -> commitSelection(id) } },
                        onDismiss = { finish() },
                    )
                }
            }
        }
    }

    private fun commitSelection(habitId: String) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val glanceId = GlanceAppWidgetManager(this@HabitudesWidgetConfigActivity)
                    .getGlanceIdBy(appWidgetId)

                withContext(Dispatchers.IO) {
                    HabitudesDatabase(this@HabitudesWidgetConfigActivity)
                        .setWidgetHabit(appWidgetId, habitId)
                }

                val remoteViews = HabitudesWidget().runComposition(
                    context = this@HabitudesWidgetConfigActivity,
                    id = glanceId,
                ).first()

                AppWidgetManager.getInstance(this@HabitudesWidgetConfigActivity)
                    .updateAppWidget(appWidgetId, remoteViews)

                val resultValue = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                setResult(RESULT_OK, resultValue)
                finish()
            } catch (_: Exception) {
                finish()
            }
        }
    }
}

@Composable
private fun EmptyHabitsDialog(onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.no_habits_title)) },
        text = { Text(stringResource(R.string.no_habits_text)) },
        confirmButton = {
            TextButton(onClick = onDismiss) { Text(stringResource(R.string.ok)) }
        },
    )
}

@Composable
private fun HabitPickerDialog(
    habits: List<HabitItem>,
    selectedId: String?,
    onSelectionChanged: (String) -> Unit,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.habit_title)) },
        text = {
            LazyColumn {
                items(habits, key = { it.id }) { habit ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth().clickable {
                            onSelectionChanged(habit.id)
                        },
                    ) {
                        RadioButton(
                            selected = habit.id == selectedId,
                            onClick = { onSelectionChanged(habit.id) },
                        )
                        Text(text = habit.name)
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onConfirm) { Text(stringResource(R.string.ok)) }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(stringResource(R.string.cancel)) }
        },
    )
}
