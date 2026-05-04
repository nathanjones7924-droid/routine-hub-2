package com.nathanjones.morningroutine.viewmodel

import android.app.AlarmManager
import android.app.Application
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.lifecycle.AndroidViewModel
import com.nathanjones.morningroutine.manager.AlarmReceiver
import com.nathanjones.morningroutine.model.Routine
import java.util.Calendar

class AlarmViewModel(application: Application) : AndroidViewModel(application) {
    private val alarmManager = application.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    fun scheduleAlarm(routine: Routine) {
        if (!routine.alarmEnabled) return
        cancelAlarm(routine)
        val intent = Intent(getApplication(), AlarmReceiver::class.java).apply {
            putExtra("routineId", routine.id)
            putExtra("routineName", routine.name)
        }
        val requestCode = routine.id.hashCode()
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val pendingIntent = PendingIntent.getBroadcast(getApplication(), requestCode, intent, flags)
        val calendar = Calendar.getInstance().apply {
            val totalMinutes = (routine.alarmTimeMillis / (1000 * 60)).toInt()
            set(Calendar.HOUR_OF_DAY, totalMinutes / 60)
            set(Calendar.MINUTE, totalMinutes % 60)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (before(Calendar.getInstance())) add(Calendar.DAY_OF_YEAR, 1)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && alarmManager.canScheduleExactAlarms()) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
        } else {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
        }
    }
    fun cancelAlarm(routine: Routine) {
        val intent = Intent(getApplication(), AlarmReceiver::class.java)
        val requestCode = routine.id.hashCode()
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val pendingIntent = PendingIntent.getBroadcast(getApplication(), requestCode, intent, flags)
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }
    fun cancelAllAlarms(routines: List<Routine>) { for (r in routines) cancelAlarm(r) }
}
