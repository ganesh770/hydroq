package com.example.hydroq

import android.app.*
import android.content.*
import android.os.Build
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.util.*

class ReminderReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_REMINDER) return

        val shouldContinue = handleReminder(context)

        // Always schedule next if enabled (even if outside window)
        if (shouldContinue) {
            scheduleNext(context)
        } else {
            // Still schedule next so it resumes later
            scheduleNext(context)
        }
    }

    private fun handleReminder(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val profileJson = prefs.getString(PROFILE_KEY, null) ?: return false

        return try {
            val profile = JSONObject(profileJson)

            val enabled = profile.optBoolean("remindersEnabled", false)
            if (!enabled) return false

            val wakeTime = profile.optInt("wakeHour", 7) * 60 +
                    profile.optInt("wakeMinute", 0)

            val sleepTimeOriginal = profile.optInt("sleepHour", 23) * 60 +
                    profile.optInt("sleepMinute", 0)

            val sleepTime =
                if (sleepTimeOriginal <= wakeTime) sleepTimeOriginal + 24 * 60 else sleepTimeOriginal

            val now = Calendar.getInstance()
            val currentMins = now.get(Calendar.HOUR_OF_DAY) * 60 +
                    now.get(Calendar.MINUTE)

            var effectiveNowMins = currentMins

            if (effectiveNowMins < wakeTime && sleepTimeOriginal <= wakeTime) {
                effectiveNowMins += 24 * 60
            }

            // Only show notification if inside window
            if (effectiveNowMins in wakeTime..sleepTime) {
                showNotification(context, profile)
            }

            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun showNotification(context: Context, profile: JSONObject) {
        val muted = profile.optBoolean("remindersMuted", false)

        val channelId = if (muted) CHANNEL_ID_MUTED else CHANNEL_ID

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = if (muted)
                NotificationManager.IMPORTANCE_LOW
            else
                NotificationManager.IMPORTANCE_HIGH

            val channel = NotificationChannel(channelId, CHANNEL_NAME, importance).apply {
                description = "Water reminder notifications"
                if (muted) setSound(null, null)
            }

            nm.createNotificationChannel(channel)
        }

        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)

        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val msg = messages.random()

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(msg.first)
            .setContentText(msg.second)
            .setPriority(
                if (muted) NotificationCompat.PRIORITY_LOW
                else NotificationCompat.PRIORITY_HIGH
            )
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)

        // Unique notification ID → prevents overwrite
        nm.notify(System.currentTimeMillis().toInt(), builder.build())
    }

    companion object {
        const val ACTION_REMINDER = "com.example.hydroq.WATER_REMINDER"

        const val CHANNEL_ID = "hydroq_reminders"
        const val CHANNEL_ID_MUTED = "hydroq_reminders_muted"
        const val CHANNEL_NAME = "Water Reminders"

        const val REQUEST_CODE = 100867734

        const val PREFS_NAME = "FlutterSharedPreferences"
        const val PROFILE_KEY = "flutter.hydroq_profile_v2"

        private val messages = listOf(
            "💧 Time to hydrate!" to "Your body needs water. Take a sip now!",
            "💧 Water break!" to "Stay on track with your daily goal.",
            "💧 Drink up!" to "A glass of water keeps dehydration away.",
            "💧 Hydration check!" to "Time for a refreshing glass of water."
        )

        fun scheduleNext(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val profileJson = prefs.getString(PROFILE_KEY, null) ?: return

            try {
                val profile = JSONObject(profileJson)

                val enabled = profile.optBoolean("remindersEnabled", false)
                if (!enabled) {
                    cancelAlarm(context)
                    return
                }

                val intervalMin = profile.optInt("reminderIntervalMinutes", 60)
                val intervalMillis = intervalMin * 60 * 1000L

                val triggerAt = System.currentTimeMillis() + intervalMillis

                val alarmManager =
                    context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

                val intent = Intent(context, ReminderReceiver::class.java).apply {
                    action = ACTION_REMINDER
                }

                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    REQUEST_CODE,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                // Proper AlarmClockInfo usage
                val showIntent = PendingIntent.getActivity(
                    context,
                    0,
                    context.packageManager.getLaunchIntentForPackage(context.packageName),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                try {
                    val alarmClockInfo = AlarmManager.AlarmClockInfo(triggerAt, showIntent)
                    alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                } catch (e: Exception) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAt,
                        pendingIntent
                    )
                }

            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        fun cancelAlarm(context: Context) {
            val alarmManager =
                context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            val intent = Intent(context, ReminderReceiver::class.java).apply {
                action = ACTION_REMINDER
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            alarmManager.cancel(pendingIntent)
        }
    }
}