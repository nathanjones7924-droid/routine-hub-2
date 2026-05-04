package com.nathanjones.morningroutine.manager

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import com.nathanjones.morningroutine.MainActivity

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val routineId = intent.getStringExtra("routineId") ?: return
        val routineName = intent.getStringExtra("routineName") ?: "Routine"

        val serviceIntent = Intent(context, AlarmService::class.java).apply {
            putExtra("routineId", routineId)
            putExtra("routineName", routineName)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        val activityIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("triggeredRoutineId", routineId)
        }
        context.startActivity(activityIntent)
    }
}
