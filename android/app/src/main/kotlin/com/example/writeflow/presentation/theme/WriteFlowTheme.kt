package com.example.writeflow.presentation.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val Canvas = Color(0xFFFCFCFA)
val Shell = Color(0xFFF1F3F0)
val Surface = Color(0xFFF6F7F4)
val Border = Color(0xFFD8DDD6)
val BorderLight = Color(0xFFE5E8E1)
val TextPrimary = Color(0xFF20231F)
val TextMuted = Color(0xFF6F766E)
val TextFaint = Color(0xFF9AA099)
val DeepGreen = Color(0xFF0F6E56)
val AccentGreen = Color(0xFF1D9E75)
val Mint = Color(0xFFE1F5EE)
val ScanLine = Color(0xFF9FE1CB)
val DarkMintText = Color(0xFF085041)
val WarmHighlight = Color(0xFFFAEEDA)
val BrownText = Color(0xFF633806)

private val WriteFlowLightScheme: ColorScheme = lightColorScheme(
    primary = DeepGreen,
    onPrimary = Mint,
    secondary = AccentGreen,
    surface = Canvas,
    onSurface = TextPrimary,
    background = Shell,
    onBackground = TextPrimary,
    outline = Border,
)

@Composable
fun WriteFlowTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = WriteFlowLightScheme,
        content = content,
    )
}
