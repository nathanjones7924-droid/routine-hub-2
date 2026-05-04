package com.nathanjones.morningroutine.ui.screen

import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Alarm
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.nathanjones.morningroutine.model.Routine
import com.nathanjones.morningroutine.ui.theme.AppTheme
import com.nathanjones.morningroutine.ui.theme.CardBackground
import com.nathanjones.morningroutine.ui.theme.PrimaryOrange
import com.nathanjones.morningroutine.ui.theme.PrimaryTextColor
import com.nathanjones.morningroutine.ui.theme.SecondaryTextColor
import com.nathanjones.morningroutine.viewmodel.RoutineViewModel
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

@Composable
fun HomeScreen(
    routineViewModel: RoutineViewModel,
    onNavigateToRoutines: () -> Unit,
    onStartRoutine: (Routine) -> Unit
) {
    val selectedRoutine = routineViewModel.selectedRoutine

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .verticalScroll(rememberScrollState())
            .padding(AppTheme.padding)
    ) {
        WelcomeHeader()
        Spacer(modifier = Modifier.height(AppTheme.paddingLarge))
        if (selectedRoutine != null) {
            SelectedRoutineCard(
                routine = selectedRoutine,
                onStart = { onStartRoutine(selectedRoutine) }
            )
        } else {
            NoRoutineCard(onCreateRoutine = onNavigateToRoutines)
        }
        Spacer(modifier = Modifier.height(AppTheme.paddingLarge))
        TipsSection()
        Spacer(modifier = Modifier.height(50.dp))
    }
}

@Composable
fun WelcomeHeader() {
    val calendar = Calendar.getInstance()
    val hour = calendar.get(Calendar.HOUR_OF_DAY)
    val greeting = when (hour) {
        in 5..<12 -> "Good Morning! \u2600\ufe0f"
        in 12..<17 -> "Good Afternoon! \u26c5"
        in 17..<21 -> "Good Evening! \ud83c\udf05"
        else -> "Good Night! \u2b50"
    }
    val dateText = SimpleDateFormat("EEEE, MMMM d", Locale.getDefault()).format(calendar.time)
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(text = greeting, style = AppTheme.largeTitle, color = PrimaryTextColor)
        Text(text = dateText, style = AppTheme.body, color = SecondaryTextColor)
    }
}

@Composable
fun SelectedRoutineCard(routine: Routine, onStart: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(AppTheme.cornerRadius),
        colors = CardDefaults.cardColors(containerColor = CardBackground),
        border = androidx.compose.foundation.BorderStroke(2.dp, PrimaryOrange)
    ) {
        Column(modifier = Modifier.padding(AppTheme.padding)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text("Today's Routine", style = AppTheme.caption, color = SecondaryTextColor)
                    Text(routine.name, style = AppTheme.title, color = PrimaryTextColor)
                }
                if (routine.alarmEnabled) {
                    Icon(
                        imageVector = Icons.Filled.Alarm,
                        contentDescription = null,
                        tint = PrimaryOrange,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
            Spacer(modifier = Modifier.height(AppTheme.padding))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                StatItem(value = "" + routine.actions.size, label = "Actions")
                Divider(modifier = Modifier.height(30.dp), color = PrimaryOrange.copy(alpha = 0.3f))
                StatItem(value = routine.formattedTotalDuration, label = "Duration")
            }
            Spacer(modifier = Modifier.height(AppTheme.padding))
            androidx.compose.material3.Button(
                onClick = onStart,
                modifier = Modifier.fillMaxWidth(),
                enabled = routine.actions.isNotEmpty(),
                shape = RoundedCornerShape(AppTheme.cornerRadius),
                colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                    containerColor = PrimaryOrange,
                    disabledContainerColor = PrimaryOrange.copy(alpha = 0.4f)
                )
            ) {
                Icon(imageVector = Icons.Default.PlayArrow, contentDescription = null)
                Text("Start Routine", style = AppTheme.headline, color = Color.White)
            }
        }
    }
}

@Composable
fun StatItem(value: String, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(text = value, style = AppTheme.headline, color = PrimaryOrange)
        Text(text = label, style = AppTheme.caption, color = SecondaryTextColor)
    }
}

@Composable
fun NoRoutineCard(onCreateRoutine: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(AppTheme.cornerRadius),
        colors = CardDefaults.cardColors(containerColor = CardBackground),
        border = androidx.compose.foundation.BorderStroke(2.dp, PrimaryOrange)
    ) {
        Column(
            modifier = Modifier.padding(AppTheme.paddingLarge),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text("\u2600\ufe0f", style = AppTheme.largeTitle, color = PrimaryOrange)
            Text("No Routine Selected", style = AppTheme.title, color = PrimaryTextColor)
            Text("Create your first morning routine to get started!", style = AppTheme.body, color = SecondaryTextColor)
            Spacer(modifier = Modifier.height(AppTheme.padding))
            androidx.compose.material3.Button(
                onClick = onCreateRoutine,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(AppTheme.cornerRadius),
                colors = androidx.compose.material3.ButtonDefaults.buttonColors(containerColor = PrimaryOrange)
            ) {
                Text("Create Routine", style = AppTheme.headline, color = Color.White)
            }
        }
    }
}

@Composable
fun TipsSection() {
    Text("Tips for Success", style = AppTheme.headline, color = PrimaryTextColor)
    Spacer(modifier = Modifier.height(AppTheme.padding))
    TipCard("\u2b50", "Prepare the Night Before", "Set out clothes and prepare breakfast items")
    Spacer(modifier = Modifier.height(AppTheme.paddingSmall))
    TipCard("\ud83d\udcf1", "Phone Away", "Keep your phone out of arm's reach")
    Spacer(modifier = Modifier.height(AppTheme.paddingSmall))
    TipCard("\u23f0", "Consistent Wake Time", "Wake up at the same time every day")
    Spacer(modifier = Modifier.height(AppTheme.paddingSmall))
    TipCard("\ud83d\udca1", "Bright Light", "Expose yourself to bright light immediately")
}

@Composable
private fun TipCard(emoji: String, title: String, desc: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(AppTheme.cornerRadiusSmall),
        colors = CardDefaults.cardColors(containerColor = CardBackground),
        border = androidx.compose.foundation.BorderStroke(1.dp, PrimaryOrange.copy(alpha = 0.5f))
    ) {
        Row(modifier = Modifier.padding(AppTheme.padding), verticalAlignment = Alignment.CenterVertically) {
            Text(emoji, style = AppTheme.title, modifier = Modifier.padding(end = AppTheme.paddingSmall))
            Column {
                Text(title, style = AppTheme.headline, color = PrimaryTextColor)
                Text(desc, style = AppTheme.caption, color = SecondaryTextColor)
            }
        }
    }
}
