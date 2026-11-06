package com.oyla.app

import android.app.*
import android.content.*
import android.net.Uri
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

object ReminderScheduler {
    private const val PREFS = "oyla_activity_reminders"
    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private fun pending(context: Context, item: JSONObject, action: String = "DELIVER"): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java).setAction(action)
            .setData(Uri.parse("oyla://reminder/${Uri.encode(item.optString("owner"))}/${Uri.encode(item.getString("id"))}/$action"))
            .putExtra("item", item.toString())
        return PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
    fun scheduleActivities(context: Context, items: JSONArray) {
        val alarms = context.getSystemService(AlarmManager::class.java)
        val previous = JSONArray(prefs(context).getString("items", "[]"))
        val manager = context.getSystemService(NotificationManager::class.java)
        for (i in 0 until previous.length()) {
            val old = previous.getJSONObject(i)
            val replacement = (0 until items.length()).map { items.getJSONObject(it) }
                .firstOrNull { it.getString("id") == old.getString("id") && it.getString("owner") == old.getString("owner") }
            if (replacement == null || replacement.getLong("at") != old.getLong("at") || replacement.optBoolean("completion") != old.optBoolean("completion")) {
                alarms.cancel(pending(context, old))
                manager.cancel((old.getString("owner") + old.getString("id")).hashCode())
            }
        }
        // Retire the original weekly workout alarms, preserving unrelated app data.
        for (id in 7401..7421) alarms.cancel(PendingIntent.getBroadcast(context,id,Intent(context,ReminderReceiver::class.java),PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
        prefs(context).edit().putString("items", items.toString()).commit()
        restore(context)
    }
    fun restore(context: Context) {
        val items = JSONArray(prefs(context).getString("items", "[]"))
        val alarms = context.getSystemService(AlarmManager::class.java)
        for (i in 0 until items.length()) {
            val item=items.getJSONObject(i)
            if(item.getLong("at")<=System.currentTimeMillis()) continue
            if (Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms()) {
                alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,item.getLong("at"),pending(context,item))
            } else {
                alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,item.getLong("at"),pending(context,item))
            }
        }
    }
    @Synchronized fun log(context: Context,item: JSONObject,type:String) {
        val queue=JSONArray(prefs(context).getString("queue","[]"))
        queue.put(JSONObject().put("eventId",UUID.randomUUID().toString()).put("id",item.getString("id")).put("owner",item.getString("owner")).put("type",type).put("at",System.currentTimeMillis()))
        prefs(context).edit().putString("queue",queue.toString()).commit()
    }
    @Synchronized fun acknowledge(context:Context,id:String) {
        val queue=JSONArray(prefs(context).getString("queue","[]"));val keep=JSONArray()
        for(i in 0 until queue.length()) {val item=queue.getJSONObject(i);if(item.getString("eventId")!=id)keep.put(item)}
        prefs(context).edit().putString("queue",keep.toString()).commit()
    }
    fun actions(context:Context): List<Map<String,Any>> {
        val queue=JSONArray(prefs(context).getString("queue","[]"))
        return (0 until queue.length()).map { val item=queue.getJSONObject(it);item.keys().asSequence().associateWith { key -> item.get(key) } }
    }
    fun cancel(context:Context) {
        scheduleActivities(context,JSONArray())
        context.getSystemService(NotificationManager::class.java).cancelAll()
    }
    fun actionIntent(context:Context,item:JSONObject,action:String): PendingIntent {
        if(action=="STARTED" || action=="OPEN") {
            val intent=Intent(context,MainActivity::class.java).setAction(action)
                .setData(Uri.parse("oyla://activity/${Uri.encode(item.getString("owner"))}/${Uri.encode(item.getString("id"))}/$action"))
                .putExtra("reminderItem",item.toString()).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            return PendingIntent.getActivity(context,0,intent,PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }
        return pending(context,item,action)
    }
    fun postpone(context:Context,item:JSONObject) {
        val next=java.util.Calendar.getInstance().apply { add(java.util.Calendar.MINUTE,30) }
        val start=item.optInt("quietStart",21);val end=item.optInt("quietEnd",8)
        val hour=next.get(java.util.Calendar.HOUR_OF_DAY)
        if(start!=end && (if(start>end) hour>=start || hour<end else hour>=start && hour<end)) return
        item.put("at",next.timeInMillis)
        val items=JSONArray(prefs(context).getString("items","[]"));val updated=JSONArray()
        for(i in 0 until items.length()) if(items.getJSONObject(i).getString("id")!=item.getString("id"))updated.put(items.getJSONObject(i))
        updated.put(item);scheduleActivities(context,updated)
    }
}
class ReminderReceiver: BroadcastReceiver() {
    override fun onReceive(context:Context,intent:Intent) {
        val raw=intent.getStringExtra("item") ?: return
        val item=try {JSONObject(raw)} catch(_:Exception){return}
        val manager=context.getSystemService(NotificationManager::class.java)
        val notificationId=(item.getString("owner")+item.getString("id")).hashCode()
        val action=intent.action ?: "DELIVER"
        if(action!="DELIVER") {
            ReminderScheduler.log(context,item,"REMINDER_OPENED")
            if(action in listOf("STARTED","POSTPONED","SKIPPED"))ReminderScheduler.log(context,item,action)
            manager.cancel(notificationId)
            if(action=="POSTPONED")ReminderScheduler.postpone(context,item)
            if(action=="STARTED" || action=="OPEN") {
                context.startActivity(Intent(context,MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP))
            }
            return
        }
        if(Build.VERSION.SDK_INT>=24 && !manager.areNotificationsEnabled())return
        val channel="daily_activities"
        val language=item.optString("language")
        fun label(en:String,kk:String,ru:String)=when(language){"kazakh"->kk;"russian"->ru;else->en}
        if(Build.VERSION.SDK_INT>=26)manager.createNotificationChannel(NotificationChannel(channel,label("Daily activities", "Күнделікті әрекеттер", "Ежедневные занятия"),NotificationManager.IMPORTANCE_DEFAULT))
        val builder=if(Build.VERSION.SDK_INT>=26)Notification.Builder(context,channel)else Notification.Builder(context)
        val completion = item.optBoolean("completion")
        builder.setSmallIcon(android.R.drawable.ic_dialog_info).setContentTitle("ÖmirAI")
            .setContentText(if (completion) label("Planned time completed", "Жоспарланған уақыт аяқталды", "Запланированное время истекло") + ": " + item.getString("title") else item.getString("title"))
            .setContentIntent(ReminderScheduler.actionIntent(context,item,"OPEN")).setAutoCancel(true)
        if (completion) {
            builder.addAction(android.R.drawable.ic_media_play,label("Open activity", "Әрекетті ашу", "Открыть занятие"),ReminderScheduler.actionIntent(context,item,"OPEN"))
        } else {
            builder.addAction(android.R.drawable.ic_media_play,label("Start","Бастау","Начать"),ReminderScheduler.actionIntent(context,item,"STARTED"))
                .addAction(android.R.drawable.ic_menu_close_clear_cancel,label("Skip","Өткізу","Пропустить"),ReminderScheduler.actionIntent(context,item,"SKIPPED"))
        }
        val notification = builder.build()
        try {manager.notify(notificationId,notification);ReminderScheduler.log(context,item,"REMINDER_SENT")} catch(_:SecurityException){ /* No false delivery event. */ }
    }
}
class ReminderBootReceiver: BroadcastReceiver() {
    override fun onReceive(context:Context,intent:Intent){ReminderScheduler.restore(context)}
}
