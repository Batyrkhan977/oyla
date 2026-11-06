package com.oyla.app
import android.Manifest
import android.content.Intent
import android.os.Bundle
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var musicVoice: MusicVoiceBridge? = null
    private var permissionResult: MethodChannel.Result? = null
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (musicVoice?.result(requestCode, resultCode, data) != true) super.onActivityResult(requestCode, resultCode, data)
    }
    override fun onDestroy() { musicVoice?.close(); super.onDestroy() }
    override fun onCreate(savedInstanceState:Bundle?) {
        super.onCreate(savedInstanceState)
        handleReminder(intent)
    }
    override fun onNewIntent(intent:Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleReminder(intent)
    }
    private fun handleReminder(intent:Intent?) {
        val raw=intent?.getStringExtra("reminderItem") ?: return
        val item=try {JSONObject(raw)} catch(_:Exception){return}
        ReminderScheduler.log(this,item,"REMINDER_OPENED")
        if(intent.action=="STARTED")ReminderScheduler.log(this,item,"STARTED")
        intent.removeExtra("reminderItem")
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        musicVoice = MusicVoiceBridge(this, MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "omirai/media"))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "oyla/youtube")
            .setMethodCallHandler { call, result ->
                if (call.method != "play") {
                    result.notImplemented()
                } else {
                    val videoId = call.argument<String>("videoId") ?: ""
                    if (!Regex("^[a-zA-Z0-9_-]{11}$").matches(videoId)) {
                        result.error("INVALID_VIDEO", "Invalid YouTube video ID", null)
                    } else {
                        try {
                            startActivity(Intent(this, YouTubePlayerActivity::class.java)
                                .putExtra("videoId", videoId)
                                .putExtra("language", call.argument<String>("language") ?: "en")
                                .putExtra("songTitle", call.argument<String>("songTitle"))
                                .putStringArrayListExtra("alternativeVideoIds",
                                    ArrayList(call.argument<List<String>>("alternativeVideoIds") ?: emptyList())))
                            result.success(null)
                        } catch (_: Exception) {
                            result.error("PLAYER_UNAVAILABLE", "Could not open player", null)
                        }
                    }
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "oyla/reminders")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "exactAlarmsEnabled" -> result.success(Build.VERSION.SDK_INT < 31 || getSystemService(android.app.AlarmManager::class.java).canScheduleExactAlarms())
                    "openExactAlarmSettings" -> {
                        if (Build.VERSION.SDK_INT >= 31) startActivity(Intent(android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                            android.net.Uri.parse("package:$packageName")))
                        result.success(null)
                    }
                    "notificationsEnabled" -> {
                        val manager = getSystemService(android.app.NotificationManager::class.java)
                        result.success(manager.areNotificationsEnabled())
                    }
                    "openNotificationSettings" -> {
                        val settingsIntent = if (Build.VERSION.SDK_INT >= 26) {
                            Intent(android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, packageName)
                        } else {
                            Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                android.net.Uri.parse("package:$packageName"))
                        }
                        startActivity(settingsIntent)
                        result.success(null)
                    }
                    "schedule" -> {
                        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            if(permissionResult != null) { result.error("PERMISSION_PENDING","Permission request in progress",null) }
                            else {permissionResult=result;requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS),41)}
                        } else result.success(null)
                    }
                    "scheduleActivities" -> {
                        val items=JSONArray()
                        for(item in call.argument<List<Map<String,Any>>>("items") ?: emptyList()) items.put(JSONObject(item))
                        ReminderScheduler.scheduleActivities(this,items); result.success(null)
                    }
                    "pendingActions" -> result.success(ReminderScheduler.actions(this))
                    "acknowledge" -> { ReminderScheduler.acknowledge(this,call.argument<String>("id") ?: "");result.success(null) }
                    "skipToday" -> result.success(null)
                    "cancel" -> { ReminderScheduler.cancel(this); result.success(null) }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "oyla/handwriting")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "recognize" -> AndroidHandwritingRecognizer.recognize(
                        call.argument("strokes"), result)
                    else -> result.notImplemented()
                }
            }
    }
    override fun onRequestPermissionsResult(requestCode:Int,permissions:Array<out String>,grantResults:IntArray) {
        super.onRequestPermissionsResult(requestCode,permissions,grantResults)
        if(requestCode==41) {
            if(grantResults.firstOrNull()==PackageManager.PERMISSION_GRANTED)permissionResult?.success(null)
            else permissionResult?.error("PERMISSION_DENIED","Notifications are disabled",null)
            permissionResult=null
        }
    }
}
