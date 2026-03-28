package app.rawdenim.tracker

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

/**
 * Handles widget tap in the background without opening the app.
 * Inserts today's wear day directly into SQLite (same DB as Flutter/sqflite).
 * Duplicate-safe: no-op if today already exists for this item.
 */
class WearDayReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != WearDayWidget.ACTION_ADD_WEAR_DAY) return
        val itemId = intent.getStringExtra("item_id") ?: return

        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                addWearDayIfNeeded(context, itemId)
                refreshWidget(context)
            } finally {
                pendingResult.finish()
            }
        }
    }

    private fun addWearDayIfNeeded(context: Context, itemId: String) {
        val dbFile = context.getDatabasePath("raw_denim_tracker.db")
        if (!dbFile.exists()) return

        val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())

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
            if (exists) return

            val uuid = UUID.randomUUID().toString()
            db.execSQL(
                "INSERT INTO wear_days (id, item_id, date) VALUES (?, ?, ?)",
                arrayOf(uuid, itemId, "${today}T00:00:00.000")
            )
        }
    }

    private fun refreshWidget(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            ComponentName(context, WearDayWidget::class.java)
        )
        for (id in ids) WearDayWidget.updateWidget(context, manager, id)
    }
}

