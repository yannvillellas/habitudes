package app.yann.habitudes

import androidx.glance.appwidget.GlanceAppWidgetManager
import io.flutter.embedding.android.FlutterActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        CoroutineScope(Dispatchers.Default).launch {
            GlanceAppWidgetManager(this@MainActivity)
                .setWidgetPreviews(HabitudesWidgetReceiver::class)
        }
    }
}
