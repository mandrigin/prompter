package com.prompter.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.prompter.db.CustomTemplateEntity
import com.prompter.ui.theme.*

// Colorful chip colors matching iOS app
private val chipColors = listOf(
    // Lavender Dream
    Pair(Color(0xFF9076E7), Color(0xFFB19BF7)),
    // Rose Quartz
    Pair(Color(0xFFE07A9C), Color(0xFFEE9FB7)),
    // Ocean Teal
    Pair(Color(0xFF54A9B3), Color(0xFF73BFC7)),
    // Sunset Gold
    Pair(Color(0xFFECAE64), Color(0xFFF4C586)),
    // Mint Fresh
    Pair(Color(0xFF77CBAA), Color(0xFF94DABE)),
    // Berry Burst
    Pair(Color(0xFFB666AC), Color(0xFFCE87C2)),
    // Sky Blue
    Pair(Color(0xFF7296E1), Color(0xFF93B3EE)),
    // Coral Reef
    Pair(Color(0xFFEF8576), Color(0xFFF6A89B))
)

@Composable
fun TemplatePicker(
    templates: List<CustomTemplateEntity>,
    onSelect: (CustomTemplateEntity) -> Unit,
    modifier: Modifier = Modifier
) {
    if (templates.isEmpty()) return

    Row(
        modifier = modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        templates.forEachIndexed { index, template ->
            TemplateChip(
                template = template,
                colorIndex = index,
                onClick = { onSelect(template) }
            )
        }
    }
}

@Composable
private fun TemplateChip(
    template: CustomTemplateEntity,
    colorIndex: Int,
    onClick: () -> Unit
) {
    val colors = chipColors[colorIndex % chipColors.size]
    val icon = getTemplateIcon(template.name)

    Box(
        modifier = Modifier
            .shadow(4.dp, RoundedCornerShape(10.dp), ambientColor = colors.first.copy(alpha = 0.3f))
            .clip(RoundedCornerShape(10.dp))
            .background(
                Brush.linearGradient(
                    colors = listOf(colors.second, colors.first)
                )
            )
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 10.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier.size(14.dp)
            )
            Text(
                text = template.name,
                color = Color.White,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

private fun getTemplateIcon(name: String): ImageVector {
    val lowerName = name.lowercase()
    return when {
        lowerName.contains("review") -> Icons.Default.RemoveRedEye
        lowerName.contains("explain") -> Icons.Default.Lightbulb
        lowerName.contains("debug") -> Icons.Default.BugReport
        lowerName.contains("fix") -> Icons.Default.Build
        lowerName.contains("refactor") -> Icons.Default.Sync
        lowerName.contains("architecture") -> Icons.Default.AccountBalance
        lowerName.contains("best") || lowerName.contains("practice") -> Icons.Default.Star
        lowerName.contains("test") -> Icons.Default.CheckCircle
        lowerName.contains("business") -> Icons.Default.TrendingUp
        lowerName.contains("technical") -> Icons.Default.Search
        else -> Icons.Default.AutoAwesome
    }
}
