package com.nathanjones.morningroutine.ui.screen

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import com.nathanjones.morningroutine.ui.theme.PrimaryOrange
import com.nathanjones.morningroutine.ui.theme.PrimaryTextColor
import com.nathanjones.morningroutine.ui.theme.SecondaryTextColor
import com.nathanjones.morningroutine.viewmodel.AlarmViewModel
import com.nathanjones.morningroutine.viewmodel.LocationViewModel
import com.nathanjones.morningroutine.viewmodel.RoutineViewModel
import com.nathanjones.morningroutine.viewmodel.TimerViewModel

sealed class Dest(val label: String, val icon: androidx.compose.ui.graphics.vector.ImageVector) {
    object Home : Dest("Home", Icons.Default.Home)
    object Routines : Dest("Routines", Icons.Default.List)
    object Settings : Dest("Settings", Icons.Default.Settings)
}

@Composable
fun MainApp() {
    var selectedTab by rememberSaveable { mutableIntStateOf(0) }
    val tabs = listOf(Dest.Home, Dest.Routines, Dest.Settings)
    val routineViewModel: RoutineViewModel = viewModel()
    val alarmViewModel: AlarmViewModel = viewModel()
    val timerViewModel: TimerViewModel = viewModel()
    val locationViewModel: LocationViewModel = viewModel()

    val routines by routineViewModel.routines.collectAsState()
    val selectedId by routineViewModel.selectedRoutineId.collectAsState()
    val currentRoutine = routines.find { it.id == selectedId }

    Scaffold(
        bottomBar = {
            NavigationBar(
                containerColor = MaterialTheme.colorScheme.surface
            ) {
                tabs.forEachIndexed { index, dest ->
                    NavigationBarItem(
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        icon = { Icon(dest.icon, contentDescription = dest.label) },
                        label = { Text(dest.label) },
                        colors = androidx.compose.material3.NavigationBarItemDefaults.colors(
                            selectedIconColor = PrimaryOrange,
                            selectedTextColor = PrimaryOrange,
                            unselectedIconColor = SecondaryTextColor,
                            unselectedTextColor = SecondaryTextColor,
                            indicatorColor = MaterialTheme.colorScheme.surfaceVariant
                        )
                    )
                }
            }
        }
    ) { padding ->
        Box(modifier = Modifier.padding(padding)) {
            when (selectedTab) {
                0 -> HomeScreen(
                    routineViewModel = routineViewModel,
                    onNavigateToRoutines = { selectedTab = 1 },
                    onStartRoutine = { routineViewModel.startRoutine(it) }
                )
                1 -> RoutinesScreen(
                    routineViewModel = routineViewModel,
                    alarmViewModel = alarmViewModel,
                    onAddRoutine = { /* TODO navigate to add */ },
                    onEditRoutine = { /* TODO */ }
                )
                2 -> SettingsScreen(
                    routineViewModel = routineViewModel,
                    alarmViewModel = alarmViewModel
                )
            }
        }
    }
}
