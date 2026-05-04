package com.nathanjones.morningroutine.model

import java.util.UUID

data class Routine(
    val id: String = UUID.randomUUID().toString(),
    val name: String = "New Routine",
    val alarmEnabled: Boolean = false,
    val alarmTimeMillis: Long = 7 * 60 * 60 * 1000L,
    val wakeUpWithSun: Boolean = false,
    val actions: List<RoutineAction> = emptyList()
) {
    val formattedAlarmTime: String
        get() {
            val totalMinutes = (alarmTimeMillis / (1000 * 60)).toInt()
            val hour = totalMinutes / 60
            val minute = totalMinutes % 60
            val amPm = if (hour < 12) "AM" else "PM"
            val displayHour = when {
                hour == 0 -> 12
                hour > 12 -> hour - 12
                else -> hour
            }
            return String.format("%d:%02d %s", displayHour, minute, amPm)
        }

    val totalDurationSeconds: Int
        get() = actions.sumOf { it.durationSeconds }

    val formattedTotalDuration: String
        get() {
            val minutes = totalDurationSeconds / 60
            return if (minutes < 60) {
                "${minutes} min"
            } else {
                val hours = minutes / 60
                val remainingMinutes = minutes % 60
                if (remainingMinutes == 0) "${hours} hr" else "${hours} hr ${remainingMinutes} min"
            }
        }
}
