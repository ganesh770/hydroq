# Notification Setup — Required Steps After `flutter create .`

After running `flutter create . --project-name hydroq`, you MUST add these to make notifications work:

## 1. Android — AndroidManifest.xml
File: `android/app/src/main/AndroidManifest.xml`

Add these permissions INSIDE `<manifest>` tag (before `<application>`):

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

Add these INSIDE `<application>` tag:

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

## 2. Android — build.gradle
File: `android/app/build.gradle`

Make sure `minSdkVersion` is at least 21:
```gradle
minSdkVersion 21
```

## 3. iOS — Info.plist  
File: `ios/Runner/Info.plist`

Add inside `<dict>`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## 4. Kotlin version (if build fails)
File: `android/build.gradle`

```gradle
ext.kotlin_version = '1.9.0'
```

## That's it!
Run `flutter pub get` then `flutter run`.
