package com.nathanjones.morningroutine.ui.screen

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Alarm
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nathanjones.morningroutine.model.Routine
import com.nathanjones.morningroutine.ui.theme.AppTheme
import com.nathanjones.morningroutine.ui.theme.CardBackground
import com.nathanjones.morningroutine.ui.theme.ElevatedBackground
import com.nathanjones.morningroutine.ui.theme.PrimaryOrange
import com.nathanjones.morningroutine.ui.theme.PrimaryTextColor
import com.nathanjones.morningroutine.ui.theme.SecondaryTextColor
import com.nathanjones.morningroutine.viewmodel.AlarmViewModel
import com.nathanjones.morningroutine.viewmodel.RoutineViewModel

@Composable
fun RoutinesScreen(
    routineViewModel: RoutineViewModel,
    alarmViewModel: AlarmViewModel,
    onAddRoutine: () -> Unit,
    onEditRoutine: (Routine) -> Unit
) {
    val routines by routineViewModel.routines.collectAsState()
    val selectedId by routineViewModel.selectedRoutineId.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .verticalScroll(rememberScrollState())
            .padding(AppTheme.padding)
    ) {
        AddRoutineButton(onClick = onAddRoutine)
        Spacer(modifier = Modifier.height(AppTheme.padding))
        if (routines.isEmpty()) {
            EmptyRoutinesState()
        } else {
            routines.forEach { routine ->
                RoutineCard(
                    routine = routine,
                    isSelected = routine.id == selectedId,
                    onSelect = {
                        routineViewModel.selectRoutine(routine)
                        alarmViewModel.scheduleAlarm(routine)
                    },
                    onEdit = { onEditRoutine(routine) },
                    onDelete = { routineViewModel.deleteRoutine(routine) }
                )
                Spacer(modifier = Modifier.height(AppTheme.padding))
            }
        }
        Spacer(modifier = Modifier.height(50.dp))
    }
}

@Composable
fun AddRoutineButton(onClick: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
        shape = RoundedCornerShape(AppTheme.cornerRadius),
        colors = CardDefaults.cardColors(containerColor = PrimaryOrange)
    ) {
        Row(
            modifier = Modifier.padding(AppTheme.padding),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.Add, contentDescription = null, tint = Color.White, modifier = Modifier.size(24.dp))
                Text("Add Routine", style = AppTheme.headline, color = Color.White, modifier = Modifier.padding(start = AppTheme.paddingSmall))
            }
            Icon(Icons.Default.Add, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
        }
    }
}

@Composable
fun EmptyRoutinesState() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 60.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("\u2705", fontSize = 64.sp, color = PrimaryOrange.copy(alpha = 0.5f))
        Spacer(modifier = Modifier.height(AppTheme.padding))
        Text("No Routines Yet", style = AppTheme.title, color = PrimaryTextColor)
        Spacer(modifier = Modifier.height(AppTheme.paddingSmall))
        Text(
            text = "Tap the button above to create your first morning routine",
            style = AppTheme.body,
            color = SecondaryTextColor,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
fun RoutineCard(
    routine: Routine,
    isSelected: Boolean,
    onSelect: () -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onEdit() },
        shape = RoundedCornerShape(AppTheme.cornerRadius),
        colors = CardDefaults.cardColors(containerColor = CardBackground),
        border = BorderStroke(2.dp, PrimaryOrange)
    ) {
        Row(
            modifier = Modifier.padding(AppTheme.padding),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) {
                SelectionIndicator(isSelected = isSelected, onSelect = onSelect)
                Spacer(modifier = Modifier.padding(start = AppTheme.paddingSmall))
                Column(modifier = Modifier.weight(1f)) {
                    Text(text = routine.name, style = AppTheme.headline, color = PrimaryTextColor)
                    Row {
                        Text("${routine.actions.size} actions", style = AppTheme.caption, color = SecondaryTextColor)
                        Spacer(modifier = Modifier.padding(horizontal = 8.dp))
                        Text(routine.formattedTotalDuration, style = AppTheme.caption, color = SecondaryTextColor)
                    }
                }
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = onDelete) {
                    Icon(Icons.Default.Delete, contentDescription = "Delete", tint = Color.Red, modifier = Modifier.size(20.dp))
                }
                if (routine.alarmEnabled) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier
                            .background(ElevatedBackground, RoundedCornerShape(AppTheme.cornerRadiusSmall))
                            .padding(6.dp)
                    ) {
                        Icon(Icons.Default.Alarm, contentDescription = "Alarm", tint = PrimaryOrange, modifier = Modifier.size(14.dp))
                        Text(routine.formattedAlarmTime, fontSize = 11.sp, color = PrimaryOrange)
                    }
                }
            }
        }
    }
}

@Composable
fun SelectionIndicator(isSelected: Boolean, onSelect: () -> Unit) {
    androidx.compose.foundation.layout.Box(
        modifier = Modifier
            .size(24.dp)
            .clickable { onSelect() },
        contentAlignment = Alignment.Center
    ) {
        androidx.compose.foundation.layout.Box(
            modifier = Modifier
                .size(24.dp)
                .background(Color.Transparent, shape = CircleShape)
                .padding(2.dp)
        ) {
            if (isSelected) {
                androidx.compose.foundation.layout.Box(
                    modifier = Modifier
                        .size(16.dp)
                        .background(PrimaryOrange, CircleShape)
                        .align(Alignment.Center)
                )
            }
        }
    }
}
