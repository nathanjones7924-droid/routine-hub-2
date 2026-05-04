package com.nathanjones.morningroutine.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// Palette
val PrimaryOrange         = Color(0xFFE85D04)
val BorderOrange          = Color(0xFFF27935)
val PrimaryTextColor      = Color(0xFFF2A35E)
val SecondaryTextColor    = Color(0xFFBF7E56)
val DarkBackground        = Color(0xFF0F0F11)
val CardBackground        = Color(0xFF1A1A1E)
val ElevatedBackground    = Color(0xFF252529)

private val DarkColorScheme = darkColorScheme(
    primary = PrimaryOrange,
    onPrimary = Color.White,
    secondary = BorderOrange,
    background = DarkBackground,
    onBackground = PrimaryTextColor,
    surface = CardBackground,
    onSurface = PrimaryTextColor,
    surfaceVariant = ElevatedBackground,
    onSurfaceVariant = SecondaryTextColor,
    outline = BorderOrange
)

object AppTheme {
    val cornerRadius = 16.dp
    val cornerRadiusSmall = 10.dp
    val padding = 16.dp
    val paddingSmall = 8.dp
    val paddingLarge = 24.dp

    val largeTitle = TextStyle(fontSize = 34.sp, fontWeight = FontWeight.Bold)
    val title = TextStyle(fontSize = 24.sp, fontWeight = FontWeight.SemiBold)
    val headline = TextStyle(fontSize = 18.sp, fontWeight = FontWeight.SemiBold)
    val body = TextStyle(fontSize = 16.sp, fontWeight = FontWeight.Normal)
    val caption = TextStyle(fontSize = 14.sp, fontWeight = FontWeight.Normal)
    val timer = TextStyle(fontSize = 72.sp, fontWeight = FontWeight.Bold)
}

@Composable
fun MorningRoutineTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = DarkColorScheme, typography = androidx.compose.material3.Typography(), content = content)
}
