package app.yann.habitudes

import androidx.glance.appwidget.GlanceAppWidgetManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
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

    private fun updateAllWidgets() {
        CoroutineScope(Dispatchers.Default).launch {
            renderAllWidgets(this@MainActivity)
        }
    }
}

