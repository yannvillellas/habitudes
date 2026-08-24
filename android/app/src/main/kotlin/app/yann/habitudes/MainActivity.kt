package app.yann.habitudes

import android.appwidget.AppWidgetManager
import androidx.glance.ExperimentalGlanceApi
import androidx.glance.appwidget.AppWidgetId
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.runComposition
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

// Channel name must match lib/data/services/widget_sync_service.dart.
private const val WIDGET_CHANNEL = "app.yann.habitudes/widget"

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        CoroutineScope(Dispatchers.Default).launch {
            GlanceAppWidgetManager(this@MainActivity)
                .setWidgetPreviews(HabitudesWidgetReceiver::class)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateAll" -> {
                        updateAllWidgets()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @OptIn(ExperimentalGlanceApi::class)
    private fun updateAllWidgets() {
        CoroutineScope(Dispatchers.Default).launch {
            val manager = GlanceAppWidgetManager(this@MainActivity)
            val appWidgetManager = AppWidgetManager.getInstance(this@MainActivity)
            val glanceIds = manager.getGlanceIds(HabitudesWidget::class.java)
            glanceIds.forEach { glanceId ->
                val remoteViews = HabitudesWidget().runComposition(this@MainActivity, glanceId).first()
                (glanceId as? AppWidgetId)?.let {
                    appWidgetManager.updateAppWidget(it.appWidgetId, remoteViews)
                }
            }
        }
    }
}

