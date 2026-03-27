package com.example.hydroq

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.util.Calendar

class ReminderReceiver : BroadcastReceiver() {

    companion object {
        const val CHANNEL_ID = "hydroq_reminders"
        const val CHANNEL_ID_MUTED = "hydroq_reminders_muted"
        const val CHANNEL_NAME = "Water Reminders"
        const val NOTIFICATION_ID = 1
        const val REQUEST_CODE = 1001
        const val PREFS_NAME = "FlutterSharedPreferences"
        const val PROFILE_KEY = "flutter.hydroq_profile_v2"

        private val messages = arrayOf(
            "💧 Time to hydrate!" to "Your body needs water. Take a sip now!",
            "💧 Water break!" to "Stay on track with your daily goal.",
            "💧 Drink up!" to "A glass of water keeps dehydration away.",
            "💧 Hydration check!" to "How's your water intake today?",
            "💧 Don't forget water!" to "Your kidneys will thank you."
        )

        fun scheduleNext(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val profileJson = prefs.getString(PROFILE_KEY, null) ?: return

            try {
                val profile = JSONObject(profileJson)
                val enabled = profile.optBoolean("remindersEnabled", false)
                if (!enabled) return

                val intervalMin = profile.optInt("reminderIntervalMinutes", 90)
                
                // Parse "7:0" format from Flutter JSON
                val wakeStr = profile.optString("wakeTime", "7:0").split(":")
                val wakeHour = wakeStr.getOrNull(0)?.toIntOrNull() ?: 7
                val wakeMinute = wakeStr.getOrNull(1)?.toIntOrNull() ?: 0
                
                val sleepStr = profile.optString("sleepTime", "23:0").split(":")
                val sleepHour = sleepStr.getOrNull(0)?.toIntOrNull() ?: 23
                val sleepMinute = sleepStr.getOrNull(1)?.toIntOrNull() ?: 0

                val now = Calendar.getInstance()
                val nextSlot = findNextSlot(
                    now, intervalMin, wakeHour, wakeMinute, sleepHour, sleepMinute
                ) ?: return

                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val intent = Intent(context, ReminderReceiver::class.java)
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    REQUEST_CODE,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                // Reverted exact alarm checks due to compilation failure. 
                // Using setAndAllowWhileIdle.
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    nextSlot.timeInMillis,
                    pendingIntent
                )
            } catch (_: Exception) {}
        }

        fun cancelAlarm(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, ReminderReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
        }

        private fun findNextSlot(
            now: Calendar,
            intervalMin: Int,
            wakeHour: Int, wakeMinute: Int,
            sleepHour: Int, sleepMinute: Int
        ): Calendar? {
            for (dayOffset in 0..2) {
                val baseDay = now.clone() as Calendar
                baseDay.add(Calendar.DAY_OF_YEAR, dayOffset)

                val wake = baseDay.clone() as Calendar
                wake.set(Calendar.HOUR_OF_DAY, wakeHour)
                wake.set(Calendar.MINUTE, wakeMinute)
                wake.set(Calendar.SECOND, 0)
                wake.set(Calendar.MILLISECOND, 0)

                val sleep = baseDay.clone() as Calendar
                sleep.set(Calendar.HOUR_OF_DAY, sleepHour)
                sleep.set(Calendar.MINUTE, sleepMinute)
                sleep.set(Calendar.SECOND, 0)
                sleep.set(Calendar.MILLISECOND, 0)

                if (sleep.before(wake) || sleep == wake) {
                    sleep.add(Calendar.DAY_OF_YEAR, 1)
                }

                val slot = wake.clone() as Calendar
                slot.add(Calendar.MINUTE, intervalMin)

                while (slot.before(sleep)) {
                    if (slot.after(now)) {
                        return slot
                    }
                    slot.add(Calendar.MINUTE, intervalMin)
                }
            }
            return null
        }
    }

    override fun onReceive(context: Context, intent: Intent?) {
        showNotification(context)
        scheduleNext(context)
    }

    private fun showNotification(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val profileJson = prefs.getString(PROFILE_KEY, null)
        val muted = try {
            JSONObject(profileJson ?: "{}").optBoolean("remindersMuted", false)
        } catch (_: Exception) { false }

        val msg = messages[(System.currentTimeMillis() % messages.size).toInt()]
        val channelId = if (muted) CHANNEL_ID_MUTED else CHANNEL_ID

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(channelId) == null) {
                val importance = if (muted) NotificationManager.IMPORTANCE_LOW else NotificationManager.IMPORTANCE_HIGH
                val channel = NotificationChannel(channelId, CHANNEL_NAME, importance)
                nm.createNotificationChannel(channel)
            }
        }

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setContentTitle(msg.first)
            .setContentText(msg.second)
            .setPriority(if (muted) NotificationCompat.PRIORITY_LOW else NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, notification)
    }
}
