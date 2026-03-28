package app.rawdenim.tracker

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.nfc.NdefMessage
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val widgetChannel = "com.example.raw_denim_tracker/widget"
    private val nfcChannelName = "app.rawdenim.tracker/nfc"

    private var nfcChannel: MethodChannel? = null

    /** URI stored here if it arrives before Flutter is ready (cold start). */
    private var pendingNfcUri: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Store any NFC URI from cold start — Flutter fetches it via getInitialNfcUri.
        pendingNfcUri = extractNfcUri(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val uri = extractNfcUri(intent) ?: return
        val ch = nfcChannel
        if (ch != null) {
            // Flutter engine is running — deliver directly.
            ch.invokeMethod("onNfcUri", uri)
        } else {
            // Shouldn't normally happen, but store as fallback.
            pendingNfcUri = uri
        }
    }

    /** Extracts a rawdenim://wear/... URI from an NDEF_DISCOVERED intent, or null. */
    private fun extractNfcUri(intent: Intent?): String? {
        if (intent?.action != "android.nfc.action.NDEF_DISCOVERED") return null
        @Suppress("DEPRECATION")
        val rawMessages = intent.getParcelableArrayExtra("android.nfc.extra.NDEF_MESSAGES")
            ?: return null
        val ndefMsg = rawMessages.firstOrNull() as? NdefMessage ?: return null
        val record = ndefMsg.records.firstOrNull() ?: return null
        val payload = record.payload
        if (payload.size < 2) return null
        // URI record payload: [identifierCode, ...utf8Uri]
        // identifierCode 0x00 = no abbreviation prefix
        val uri = String(payload, 1, payload.size - 1, Charsets.UTF_8)
        return if (uri.startsWith("rawdenim://wear/")) uri else null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWidget" -> {
                        val manager = AppWidgetManager.getInstance(this)
                        val ids = manager.getAppWidgetIds(
                            ComponentName(this, WearDayWidget::class.java)
                        )
                        for (id in ids) {
                            WearDayWidget.updateWidget(this, manager, id)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, nfcChannelName)
        nfcChannel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialNfcUri" -> {
                    result.success(pendingNfcUri)
                    pendingNfcUri = null
                }
                else -> result.notImplemented()
            }
        }
    }
}


