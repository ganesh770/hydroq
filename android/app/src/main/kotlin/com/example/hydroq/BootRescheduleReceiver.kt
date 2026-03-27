package com.example.hydroq

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootRescheduleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED ||
            intent?.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent?.action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            ReminderReceiver.scheduleNext(context)
        }
    }
}
