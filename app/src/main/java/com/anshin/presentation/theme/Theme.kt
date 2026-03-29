package com.anshin.presentation.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val LightColors = lightColorScheme(
    primary = ForestGreen,
    onPrimary = BaseBackground,
    secondary = ActionGreen,
    tertiary = SoftGreen,
    background = BaseBackground,
    onBackground = TextPrimary,
    surface = BaseBackground,
    onSurface = TextPrimary,
    surfaceVariant = SurfaceMuted,
    onSurfaceVariant = TextSecondary,
    outline = ActionGreen.copy(alpha = 0.28f)
)

private val DarkColors = darkColorScheme(
    primary = SoftGreen,
    onPrimary = TextPrimary,
    secondary = AccentMint,
    tertiary = WarmHighlight,
    background = ForestGreen,
    onBackground = PaleGreen,
    surface = ForestGreen,
    onSurface = PaleGreen,
    surfaceVariant = ActionGreen,
    onSurfaceVariant = PaleGreen
)

@Composable
fun AnshinTheme(
    useDarkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = if (useDarkTheme) DarkColors else LightColors,
        typography = Typography,
        content = content
    )
}
