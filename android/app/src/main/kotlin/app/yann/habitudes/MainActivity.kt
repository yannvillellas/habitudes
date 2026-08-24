package app.yann.habitudes

import android.content.Intent
import androidx.glance.appwidget.GlanceAppWidgetManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

// Channel name must match lib/data/services/widget_sync_service.dart.
private const val WIDGET_CHANNEL = "app.yann.habitudes/widget"

// Intent extra carrying the habit id when the widget opens the app.
const val EXTRA_HABIT_ID = "habit_id"

class MainActivity : FlutterActivity() {

    private var widgetChannel: MethodChannel? = null

    // Routing comes from the habit_id intent extra, not from intent data: the
    // Glance action trampoline sets data to an internal glance-action URI,
    // which would otherwise be treated as a deep link and break cold starts.
    override fun shouldHandleDeeplinking(): Boolean = false

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        CoroutineScope(Dispatchers.Default).launch {
            GlanceAppWidgetManager(this@MainActivity)
                .setWidgetPreviews(HabitudesWidgetReceiver::class)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
        widgetChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateAll" -> {
                    updateAllWidgets()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        intent.getStringExtra(EXTRA_HABIT_ID)?.let { habitId ->
            flutterEngine.navigationChannel.setInitialRoute("/habit/$habitId")
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.getStringExtra(EXTRA_HABIT_ID)?.let { habitId ->
            widgetChannel?.invokeMethod("openHabit", habitId)
        }
    }

    private fun updateAllWidgets() {
        CoroutineScope(Dispatchers.Default).launch {
            renderAllWidgets(this@MainActivity)
        }
    }
}

