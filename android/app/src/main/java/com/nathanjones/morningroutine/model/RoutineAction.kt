package com.nathanjones.morningroutine.model

import java.util.UUID

data class RoutineAction(
    val id: String = UUID.randomUUID().toString(),
    val name: String = "",
    val durationSeconds: Int = 60,
    val useRedFilter: Boolean = false,
    val isAlarmEnabled: Boolean = true
) {
    val formattedDuration: String
        get() {
            val minutes = durationSeconds / 60
            val seconds = durationSeconds % 60
            return String.format("%d:%02d", minutes, seconds)
        }
}
