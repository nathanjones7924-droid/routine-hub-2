package com.nathanjones.morningroutine.manager

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.core.app.NotificationCompat
import com.nathanjones.morningroutine.MainActivity
import com.nathanjones.morningroutine.MorningRoutineApplication

class AlarmService : Service() {
    private var vibrator: Vibrator? = null
    private var notificationManager: NotificationManager? = null

    companion object {
        const val NOTIFICATION_ID = 1001
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val routineId = intent?.getStringExtra("routineId") ?: return START_NOT_STICKY
        val routineName = intent.getStringExtra("routineName") ?: "Routine"

        val notification = buildNotification(routineName, routineId)
        startForeground(NOTIFICATION_ID, notification)

        vibrate()
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        vibrator?.cancel()
    }

    private fun buildNotification(routineName: String, routineId: String): Notification {
        val contentIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("triggeredRoutineId", routineId)
        }
        val contentPending = PendingIntent.getActivity(
            this, 0, contentIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val snoozeIntent = Intent(this, AlarmService::class.java).apply {
            action = "SNOOZE"
            putExtra("routineId", routineId)
        }
        val snoozePending = PendingIntent.getService(
            this, 1, snoozeIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, MorningRoutineApplication.CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("\u23f0  $routineName")
            .setContentText("Time to start your morning routine!")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setContentIntent(contentPending)
            .addAction(android.R.drawable.ic_media_pause, "Snooze 5 min", snoozePending)
            .setAutoCancel(true)
            .build()
    }

    private fun vibrate() {
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = VibrationEffect.createWaveform(longArrayOf(0, 500, 500), 0)
            vibrator?.vibrate(effect)
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(longArrayOf(0, 500, 500), 0)
        }
    }
}
