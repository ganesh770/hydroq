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

    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val profileJson = prefs.getString(PROFILE_KEY, null) ?: return
        
        try {
            val profile = JSONObject(profileJson)
            val enabled = profile.optBoolean("remindersEnabled", false)
            if (!enabled) return

            // Parse Wake and Sleep directly from JSON string e.g "7:0" or "23:0"
            val wakeTime = profile.optInt("wakeHour", 7) * 60 + profile.optInt("wakeMinute", 0)
            val sleepTimeOriginal = profile.optInt("sleepHour", 23) * 60 + profile.optInt("sleepMinute", 0)
            
            val sleepTime = if (sleepTimeOriginal <= wakeTime) sleepTimeOriginal + 24 * 60 else sleepTimeOriginal
            
            val now = Calendar.getInstance()
            val currentMins = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
            
            var effectiveNowMins = currentMins
            if (effectiveNowMins < wakeTime && sleepTimeOriginal <= wakeTime) {
                // We are after midnight but before wake time, in an overnight sleep schedule.
                effectiveNowMins += 24 * 60
            }

            // We drop out if the current time is NOT between wake and sleep
            if (effectiveNowMins !in wakeTime..sleepTime) {
                return
            }

            // If we're inside wake/sleep bounds, we show the actual notification!
            showNotification(context, profile)

        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun showNotification(context: Context, profile: JSONObject) {
        val muted = profile.optBoolean("remindersMuted", false)

        val channelId = if (muted) CHANNEL_ID_MUTED else CHANNEL_ID
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = if (muted) NotificationManager.IMPORTANCE_LOW else NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(channelId, CHANNEL_NAME, importance).apply {
                description = "Reminders to drink water throughout the day"
                if (muted) {
                    setSound(null, null)
                }
            }
            val notificationManager: NotificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val msg = messages.random()

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(msg.first)
            .setContentText(msg.second)
            .setPriority(if (muted) NotificationCompat.PRIORITY_LOW else NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, builder.build())
    }

    companion object {
        const val CHANNEL_ID = "hydroq_reminders"
        const val CHANNEL_ID_MUTED = "hydroq_reminders_muted"
        const val CHANNEL_NAME = "Water Reminders"
        const val NOTIFICATION_ID = 4829
        const val REQUEST_CODE = 100867734
        const val PREFS_NAME = "FlutterSharedPreferences"
        const val PROFILE_KEY = "flutter.hydroq_profile_v2"

        private val messages = listOf(
            Pair("💧 Time to hydrate!", "Your body needs water. Take a sip now!"),
            Pair("💧 Water break!", "Stay on track with your daily goal."),
            Pair("💧 Drink up!", "A glass of water keeps dehydration away."),
            Pair("💧 Hydration check!", "Time for a refreshing glass of water.")
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

                // TEMPORARY: Forcing 1-minute intervals to allow for immediate testing!
                // val intervalMin = profile.optInt("reminderIntervalMinutes", 60)
                val intervalMillis = 1 * 60 * 1000L // 1 MINUTE FOR TESTING

                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val intent = Intent(context, ReminderReceiver::class.java).apply {
                    action = "com.example.hydroq.WATER_REMINDER"
                }

                val pendingIntent = PendingIntent.getBroadcast(
                    context, REQUEST_CODE, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                // The reference app implementation: setRepeating
                alarmManager.setRepeating(
                    AlarmManager.RTC_WAKEUP,
                    System.currentTimeMillis() + intervalMillis,
                    intervalMillis,
                    pendingIntent
                )
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        fun cancelAlarm(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, ReminderReceiver::class.java).apply {
                action = "com.example.hydroq.WATER_REMINDER"
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, REQUEST_CODE, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
        }
    }
}
