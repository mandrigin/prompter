package com.prompter.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Nothing OS 4.0 Theme
 *
 * Visual language characteristics:
 * - Dot-matrix aesthetic with NDot font family
 * - Monochromatic palette: pure black, white, with red accents
 * - High contrast for readability
 * - Clean geometric shapes
 * - Glyph-style iconography
 */

// Nothing OS Color Palette
object NothingColors {
    // Primary monochrome
    val Black = Color(0xFF000000)
    val White = Color(0xFFFFFFFF)
    val DarkGray = Color(0xFF1A1A1A)
    val MediumGray = Color(0xFF2D2D2D)
    val LightGray = Color(0xFFE5E5E5)
    val SubtleGray = Color(0xFF8A8A8A)

    // Accent - Nothing's signature red
    val Red = Color(0xFFD71921)
    val RedLight = Color(0xFFFF4D4D)
    val RedDark = Color(0xFFB01018)

    // Functional colors
    val Success = Color(0xFF4CAF50)
    val Warning = Color(0xFFFFC107)
    val Error = Red

    // Surface variants
    val SurfaceDark = DarkGray
    val SurfaceLight = White
    val SurfaceContainerDark = MediumGray
    val SurfaceContainerLight = LightGray
}

// NDot-inspired font family (fallback to system monospace)
// In production, include actual NDot font files in res/font/
val NDotFontFamily = FontFamily.Monospace

// Nothing OS Typography
object NothingTypography {
    val displayLarge = TextStyle(
        fontFamily = NDotFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 57.sp,
        lineHeight = 64.sp,
        letterSpacing = (-0.25).sp
    )

    val displayMedium = TextStyle(
        fontFamily = NDotFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 45.sp,
        lineHeight = 52.sp,
        letterSpacing = 0.sp
    )

    val displaySmall = TextStyle(
        fontFamily = NDotFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 36.sp,
        lineHeight = 44.sp,
        letterSpacing = 0.sp
    )

    val headlineLarge = TextStyle(
        fontFamily = NDotFontFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 32.sp,
        lineHeight = 40.sp,
        letterSpacing = 0.sp
    )

    val headlineMedium = TextStyle(
        fontFamily = NDotFontFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 28.sp,
        lineHeight = 36.sp,
        letterSpacing = 0.sp
    )

    val headlineSmall = TextStyle(
        fontFamily = NDotFontFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 24.sp,
        lineHeight = 32.sp,
        letterSpacing = 0.sp
    )

    val titleLarge = TextStyle(
        fontFamily = NDotFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 22.sp,
        lineHeight = 28.sp,
        letterSpacing = 0.sp
    )

    val titleMedium = TextStyle(
        fontFamily = NDotFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.15.sp
    )

    val titleSmall = TextStyle(
        fontFamily = NDotFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.1.sp
    )

    val bodyLarge = TextStyle(
        fontFamily = NDotFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.5.sp
    )

    val bodyMedium = TextStyle(
        fontFamily = NDotFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.25.sp
    )

    val bodySmall = TextStyle(
        fontFamily = NDotFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.4.sp
    )

    val labelLarge = TextStyle(
        fontFamily = NDotFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.1.sp
    )

    val labelMedium = TextStyle(
        fontFamily = NDotFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.5.sp
    )

    val labelSmall = TextStyle(
        fontFamily = NDotFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 11.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.5.sp
    )
}

// Material3 Typography instance
val NothingMaterialTypography = Typography(
    displayLarge = NothingTypography.displayLarge,
    displayMedium = NothingTypography.displayMedium,
    displaySmall = NothingTypography.displaySmall,
    headlineLarge = NothingTypography.headlineLarge,
    headlineMedium = NothingTypography.headlineMedium,
    headlineSmall = NothingTypography.headlineSmall,
    titleLarge = NothingTypography.titleLarge,
    titleMedium = NothingTypography.titleMedium,
    titleSmall = NothingTypography.titleSmall,
    bodyLarge = NothingTypography.bodyLarge,
    bodyMedium = NothingTypography.bodyMedium,
    bodySmall = NothingTypography.bodySmall,
    labelLarge = NothingTypography.labelLarge,
    labelMedium = NothingTypography.labelMedium,
    labelSmall = NothingTypography.labelSmall
)

// Nothing OS Shapes - clean geometric forms
val NothingShapes = Shapes(
    extraSmall = RoundedCornerShape(4.dp),
    small = RoundedCornerShape(8.dp),
    medium = RoundedCornerShape(12.dp),
    large = RoundedCornerShape(16.dp),
    extraLarge = RoundedCornerShape(24.dp)
)

// Dark color scheme (primary Nothing aesthetic)
private val NothingDarkColorScheme = darkColorScheme(
    primary = NothingColors.White,
    onPrimary = NothingColors.Black,
    primaryContainer = NothingColors.MediumGray,
    onPrimaryContainer = NothingColors.White,

    secondary = NothingColors.Red,
    onSecondary = NothingColors.White,
    secondaryContainer = NothingColors.RedDark,
    onSecondaryContainer = NothingColors.White,

    tertiary = NothingColors.SubtleGray,
    onTertiary = NothingColors.Black,
    tertiaryContainer = NothingColors.DarkGray,
    onTertiaryContainer = NothingColors.LightGray,

    background = NothingColors.Black,
    onBackground = NothingColors.White,

    surface = NothingColors.Black,
    onSurface = NothingColors.White,
    surfaceVariant = NothingColors.DarkGray,
    onSurfaceVariant = NothingColors.LightGray,

    surfaceContainerLowest = NothingColors.Black,
    surfaceContainerLow = NothingColors.DarkGray,
    surfaceContainer = NothingColors.MediumGray,
    surfaceContainerHigh = NothingColors.MediumGray,
    surfaceContainerHighest = NothingColors.SubtleGray,

    outline = NothingColors.SubtleGray,
    outlineVariant = NothingColors.MediumGray,

    error = NothingColors.Error,
    onError = NothingColors.White,
    errorContainer = NothingColors.RedDark,
    onErrorContainer = NothingColors.White,

    inverseSurface = NothingColors.White,
    inverseOnSurface = NothingColors.Black,
    inversePrimary = NothingColors.Black,

    scrim = NothingColors.Black.copy(alpha = 0.5f)
)

// Light color scheme (inverted Nothing aesthetic)
private val NothingLightColorScheme = lightColorScheme(
    primary = NothingColors.Black,
    onPrimary = NothingColors.White,
    primaryContainer = NothingColors.LightGray,
    onPrimaryContainer = NothingColors.Black,

    secondary = NothingColors.Red,
    onSecondary = NothingColors.White,
    secondaryContainer = NothingColors.RedLight,
    onSecondaryContainer = NothingColors.Black,

    tertiary = NothingColors.SubtleGray,
    onTertiary = NothingColors.White,
    tertiaryContainer = NothingColors.LightGray,
    onTertiaryContainer = NothingColors.DarkGray,

    background = NothingColors.White,
    onBackground = NothingColors.Black,

    surface = NothingColors.White,
    onSurface = NothingColors.Black,
    surfaceVariant = NothingColors.LightGray,
    onSurfaceVariant = NothingColors.DarkGray,

    surfaceContainerLowest = NothingColors.White,
    surfaceContainerLow = NothingColors.LightGray,
    surfaceContainer = NothingColors.LightGray,
    surfaceContainerHigh = NothingColors.SubtleGray,
    surfaceContainerHighest = NothingColors.MediumGray,

    outline = NothingColors.SubtleGray,
    outlineVariant = NothingColors.LightGray,

    error = NothingColors.Error,
    onError = NothingColors.White,
    errorContainer = NothingColors.RedLight,
    onErrorContainer = NothingColors.Black,

    inverseSurface = NothingColors.Black,
    inverseOnSurface = NothingColors.White,
    inversePrimary = NothingColors.White,

    scrim = NothingColors.Black.copy(alpha = 0.3f)
)

/**
 * Nothing OS 4.0 Theme composable
 *
 * @param darkTheme Whether to use dark theme (default follows system)
 * @param content The composable content to theme
 */
@Composable
fun NothingTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) {
        NothingDarkColorScheme
    } else {
        NothingLightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = NothingMaterialTypography,
        shapes = NothingShapes,
        content = content
    )
}
