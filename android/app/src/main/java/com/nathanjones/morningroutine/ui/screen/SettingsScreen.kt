package com.nathanjones.morningroutine.ui.screen

import androidx.compose.foundation.BorderStroke
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
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.nathanjones.morningroutine.ui.theme.AppTheme
import com.nathanjones.morningroutine.ui.theme.CardBackground
import com.nathanjones.morningroutine.ui.theme.PrimaryOrange
import com.nathanjones.morningroutine.ui.theme.PrimaryTextColor
import com.nathanjones.morningroutine.ui.theme.SecondaryTextColor
import com.nathanjones.morningroutine.viewmodel.AlarmViewModel
import com.nathanjones.morningroutine.viewmodel.RoutineViewModel

@Composable
fun SettingsScreen(
    routineViewModel: RoutineViewModel,
    alarmViewModel: AlarmViewModel
) {
    val routines by routineViewModel.routines.collectAsState()
    var showResetDialog by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .verticalScroll(rememberScrollState())
            .padding(AppTheme.padding)
    ) {
        Text("Settings", style = AppTheme.largeTitle, color = PrimaryTextColor)

        Spacer(modifier = Modifier.height(AppTheme.paddingLarge))
        Text("Notifications", style = AppTheme.headline, color = PrimaryTextColor)
        Spacer(modifier = Modifier.height(AppTheme.paddingSmall))
        Card(
            shape = RoundedCornerShape(AppTheme.cornerRadius),
            colors = CardDefaults.cardColors(containerColor = CardBackground),
            border = BorderStroke(1.dp, PrimaryOrange.copy(alpha = 0.5f))
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(AppTheme.padding),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Default.Info, contentDescription = null, tint = PrimaryOrange, modifier = Modifier.size(24.dp))
                Spacer(modifier = Modifier.padding(start = AppTheme.paddingSmall))
                Column(modifier = Modifier.weight(1f)) {
                    Text("Alarm Notifications", style = AppTheme.body, color = PrimaryTextColor)
                    Text("Managed via system settings", style = AppTheme.caption, color = SecondaryTextColor)
                }
            }
        }

        Spacer(modifier = Modifier.height(AppTheme.paddingLarge))
        Text("About", style = AppTheme.headline, color = PrimaryTextColor)
        Spacer(modifier = Modifier.height(AppTheme.paddingSmall))
        Card(
            shape = RoundedCornerShape(AppTheme.cornerRadius),
            colors = CardDefaults.cardColors(containerColor = CardBackground),
            border = BorderStroke(1.dp, PrimaryOrange.copy(alpha = 0.5f))
        ) {
            AboutRow(label = "App Version", value = "1.0.0")
            Divider(color = PrimaryOrange.copy(alpha = 0.3f), modifier = Modifier.padding(horizontal = 16.dp))
            AboutRow(label = "Build", value = "1")
            Divider(color = PrimaryOrange.copy(alpha = 0.3f), modifier = Modifier.padding(horizontal = 16.dp))
            AboutRow(label = "Developer", value = "Morning Routine Team")
        }

        Spacer(modifier = Modifier.height(AppTheme.paddingLarge))
        Text("Data", style = AppTheme.headline, color = PrimaryTextColor)
        Spacer(modifier = Modifier.height(AppTheme.paddingSmall))
        Card(
            shape = RoundedCornerShape(AppTheme.cornerRadius),
            colors = CardDefaults.cardColors(containerColor = CardBackground),
            border = BorderStroke(1.dp, PrimaryOrange.copy(alpha = 0.5f))
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(AppTheme.padding),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text("Total Routines", style = AppTheme.body, color = PrimaryTextColor)
                    Text("${routines.size} routine(s)", style = AppTheme.caption, color = SecondaryTextColor)
                }
                Icon(Icons.Default.Info, contentDescription = null, tint = PrimaryOrange)
            }
            Divider(color = PrimaryOrange.copy(alpha = 0.3f), modifier = Modifier.padding(horizontal = 16.dp))
            TextButton(
                onClick = { showResetDialog = true },
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(Icons.Default.Delete, contentDescription = null, tint = Color.Red)
                Spacer(modifier = Modifier.padding(start = AppTheme.paddingSmall))
                Text("Reset All Data", color = Color.Red)
            }
        }
    }

    if (showResetDialog) {
        AlertDialog(
            onDismissRequest = { showResetDialog = false },
            title = { Text("Reset All Data", color = PrimaryTextColor) },
            text = { Text("This will delete all routines. This action cannot be undone.", color = SecondaryTextColor) },
            confirmButton = {
                TextButton(onClick = {
                    routineViewModel.resetAllData()
                    alarmViewModel.cancelAllAlarms(routines)
                    showResetDialog = false
                }) { Text("Reset", color = Color.Red) }
            },
            dismissButton = {
                TextButton(onClick = { showResetDialog = false }) { Text("Cancel", color = PrimaryTextColor) }
            }
        )
    }
}

@Composable
private fun AboutRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(AppTheme.padding),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label, color = PrimaryTextColor)
        Text(value, color = SecondaryTextColor)
    }
}
