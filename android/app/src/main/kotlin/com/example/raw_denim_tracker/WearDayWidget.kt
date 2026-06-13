package app.rawdenim.tracker

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.*

class WearDayWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) updateWidget(context, appWidgetManager, id)
        // (Re)arm the midnight alarm whenever the system updates the widget.
        scheduleMidnightRefresh(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleMidnightRefresh(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // Last widget removed — stop the daily alarm.
        cancelMidnightRefresh(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        // Force a redraw on midnight rollover / time changes so the
        // "worn today" indicator updates without waiting for the next
        // appwidget update tick. ACTION_DATE_CHANGED alone is unreliable on
        // OEM ROMs that defer implicit broadcasts during Doze, so the primary
        // mechanism is our own midnight AlarmManager (ACTION_MIDNIGHT_REFRESH).
        when (intent.action) {
            ACTION_MIDNIGHT_REFRESH,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_BOOT_COMPLETED -> {
                refreshAll(context)
                // Re-anchor for the next midnight (alarms don't survive reboot,
                // and manual time changes move the target).
                scheduleMidnightRefresh(context)
            }
        }
    }

    companion object {
        const val ACTION_ADD_WEAR_DAY = "app.rawdenim.tracker.ADD_WEAR_DAY"
        const val ACTION_MIDNIGHT_REFRESH = "app.rawdenim.tracker.MIDNIGHT_REFRESH"

        private fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, WearDayWidget::class.java)
            )
            for (id in ids) updateWidget(context, manager, id)
        }

        /// Schedules a one-shot alarm for the next local midnight (+5s buffer).
        /// Uses setAndAllowWhileIdle so it fires even in Doze, without needing
        /// the exact-alarm permission. The handler re-schedules the next one,
        /// forming a daily chain.
        fun scheduleMidnightRefresh(context: Context) {
            val alarmManager =
                context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val cal = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 5)
                set(Calendar.MILLISECOND, 0)
            }
            try {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC, cal.timeInMillis, midnightPendingIntent(context)
                )
            } catch (_: Exception) { /* best-effort; DATE_CHANGED is the fallback */ }
        }

        fun cancelMidnightRefresh(context: Context) {
            val alarmManager =
                context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val existing = PendingIntent.getBroadcast(
                context, 1,
                Intent(context, WearDayWidget::class.java).apply { action = ACTION_MIDNIGHT_REFRESH },
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            if (existing != null) alarmManager.cancel(existing)
        }

        private fun midnightPendingIntent(context: Context): PendingIntent =
            PendingIntent.getBroadcast(
                context, 1,
                Intent(context, WearDayWidget::class.java).apply { action = ACTION_MIDNIGHT_REFRESH },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val data = HomeWidgetPlugin.getData(context)
            val itemId   = data.getString("widget_item_id", null)
            val itemName = data.getString("widget_item_name", "No item selected")
            val photoPath = data.getString("widget_photo_path", null)
            val monochrome = data.getBoolean("widget_monochrome", false)

            // Count = base_wear_count + tracked rows
            val count = getTotalCount(context, itemId)

            // Locale.US guarantees ASCII digits — Locale.getDefault() can produce
            // non-Latin numerals (e.g. Arabic), which break the LIKE comparison
            // against ISO-formatted date strings stored by Flutter.
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val wornToday = itemId != null && wornTodayExists(context, itemId, today)

            val views = RemoteViews(context.packageName, R.layout.wear_day_widget)

            // Photo (desaturated in monochrome mode for Nothing OS aesthetic)
            val rawBitmap = photoPath?.let { loadBitmap(it) }
            val bitmap = if (monochrome && rawBitmap != null) toGrayscale(rawBitmap) else rawBitmap
            if (bitmap != null) {
                views.setImageViewBitmap(R.id.widget_photo, bitmap)
            } else {
                views.setImageViewResource(R.id.widget_photo, R.mipmap.ic_launcher)
            }

            // Count label
            views.setTextViewText(R.id.widget_wear_count, "$count days")

            // Checkmark if already worn today
            views.setViewVisibility(
                R.id.widget_check,
                if (wornToday) android.view.View.VISIBLE else android.view.View.GONE
            )

            // Tap: if already worn today → open app; otherwise → add wear day silently
            val tapPending = if (wornToday) {
                val launchIntent = context.packageManager
                    .getLaunchIntentForPackage(context.packageName)
                    ?.apply { addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK) }
                PendingIntent.getActivity(
                    context, appWidgetId + 10000, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            } else {
                val broadcastIntent = Intent(context, WearDayReceiver::class.java).apply {
                    action = ACTION_ADD_WEAR_DAY
                    putExtra("item_id", itemId)
                }
                PendingIntent.getBroadcast(
                    context, appWidgetId, broadcastIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            }
            views.setOnClickPendingIntent(R.id.widget_root, tapPending)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun getTotalCount(context: Context, itemId: String?): Int {
            if (itemId == null) return 0
            val dbFile = context.getDatabasePath("raw_denim_tracker.db")
            if (!dbFile.exists()) return 0
            return try {
                SQLiteDatabase.openDatabase(dbFile.path, null, SQLiteDatabase.OPEN_READONLY)
                    .use { db ->
                        // base_wear_count from item
                        val itemCur = db.rawQuery(
                            "SELECT base_wear_count FROM items WHERE id = ?", arrayOf(itemId)
                        )
                        val base = if (itemCur.moveToFirst()) itemCur.getInt(0) else 0
                        itemCur.close()
                        // tracked rows
                        val wdCur = db.rawQuery(
                            "SELECT COUNT(*) FROM wear_days WHERE item_id = ?", arrayOf(itemId)
                        )
                        val tracked = if (wdCur.moveToFirst()) wdCur.getInt(0) else 0
                        wdCur.close()
                        base + tracked
                    }
            } catch (e: Exception) { 0 }
        }

        private fun wornTodayExists(context: Context, itemId: String, today: String): Boolean {
            val dbFile = context.getDatabasePath("raw_denim_tracker.db")
            if (!dbFile.exists()) return false
            return try {
                SQLiteDatabase.openDatabase(dbFile.path, null, SQLiteDatabase.OPEN_READONLY)
                    .use { db ->
                        val cur = db.rawQuery(
                            "SELECT id FROM wear_days WHERE item_id = ? AND date LIKE ?",
                            arrayOf(itemId, "$today%")
                        )
                        val exists = cur.count > 0
                        cur.close()
                        exists
                    }
            } catch (e: Exception) { false }
        }

        /// Desaturates a bitmap. Used when the user enables monochrome rendering
        /// (e.g. on Nothing OS). Pure black & white via setSaturation(0f).
        private fun toGrayscale(src: Bitmap): Bitmap {
            val out = Bitmap.createBitmap(src.width, src.height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(out)
            val paint = Paint().apply {
                colorFilter = ColorMatrixColorFilter(ColorMatrix().apply { setSaturation(0f) })
            }
            canvas.drawBitmap(src, 0f, 0f, paint)
            return out
        }

        private fun loadBitmap(path: String, maxPx: Int = 300): Bitmap? = try {
            // First pass: read dimensions only
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            // Calculate sample size to stay within maxPx
            val largest = maxOf(bounds.outWidth, bounds.outHeight).coerceAtLeast(1)
            var sampleSize = 1
            while (largest / (sampleSize * 2) >= maxPx) sampleSize *= 2
            // Second pass: decode at reduced size
            BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sampleSize })
        } catch (e: Exception) { null }
    }
}

