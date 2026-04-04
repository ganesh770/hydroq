package com.example.hydroq

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.hydroq/reminder"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleNext" -> {
                    ReminderReceiver.scheduleNext(this)
                    result.success(null)
                }
                "cancelAlarm" -> {
                    ReminderReceiver.cancelAlarm(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
