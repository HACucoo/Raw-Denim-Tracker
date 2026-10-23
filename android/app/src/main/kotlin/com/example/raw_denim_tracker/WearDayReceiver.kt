package app.rawdenim.tracker

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

/**
 * Handles widget tap in the background without opening the app.
 * Inserts today's wear day directly into SQLite (same DB as Flutter/sqflite).
 * Duplicate-safe: no-op if today already exists for this item.
 *
 * Nothing of the Flutter app runs here, so after a new row it raises home_widget's background
 * receiver, which starts a headless Dart engine that pushes the change to Home Assistant
 * (lib/services/widget_background.dart). Best-effort: the next app start sends everything anyway.
 */
class WearDayReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != WearDayWidget.ACTION_ADD_WEAR_DAY) return
        val itemId = intent.getStringExtra("item_id") ?: return

        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val inserted = addWearDayIfNeeded(context, itemId)
                refreshWidget(context)
                if (inserted) notifyApp(context, itemId)
            } finally {
                pendingResult.finish()
            }
        }
    }

    /** Returns true when a row was written, false when today already existed or there is no database. */
    private fun addWearDayIfNeeded(context: Context, itemId: String): Boolean {
        val dbFile = context.getDatabasePath("raw_denim_tracker.db")
        if (!dbFile.exists()) return false

        // Locale.US — ASCII digits, matches Flutter's ISO-format strings.
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

        SQLiteDatabase.openDatabase(
            dbFile.path, null, SQLiteDatabase.OPEN_READWRITE
        ).use { db ->
            // Check duplicate
            val cur = db.rawQuery(
                "SELECT id FROM wear_days WHERE item_id = ? AND date LIKE ?",
                arrayOf(itemId, "$today%")
            )
            val exists = cur.count > 0
            cur.close()
            if (exists) return false

            val uuid = UUID.randomUUID().toString()
            db.execSQL(
                "INSERT INTO wear_days (id, item_id, date) VALUES (?, ?, ?)",
                arrayOf(uuid, itemId, "${today}T00:00:00.000")
            )
            return true
        }
    }

    /** Hands the new wear day to the Dart background callback registered in main() (HA push). */
    private fun notifyApp(context: Context, itemId: String) {
        val intent = Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
            action = "es.antonborri.home_widget.action.BACKGROUND"
            data = Uri.parse("rawdenim://widget/wear-day-added?item=$itemId")
        }
        context.sendBroadcast(intent)
    }

    private fun refreshWidget(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            ComponentName(context, WearDayWidget::class.java)
        )
        for (id in ids) WearDayWidget.updateWidget(context, manager, id)
    }
}

