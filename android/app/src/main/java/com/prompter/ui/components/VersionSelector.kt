package com.prompter.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.prompter.db.PromptVersionEntity
import com.prompter.ui.theme.*
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun VersionSelector(
    versions: List<PromptVersionEntity>,
    selectedIndex: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    if (versions.size <= 1) return

    Row(
        modifier = modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        versions.forEachIndexed { index, version ->
            VersionTab(
                index = index,
                timestamp = version.timestamp,
                isSelected = index == selectedIndex,
                isLatest = index == versions.lastIndex,
                onClick = { onSelect(index) }
            )
        }
    }
}

@Composable
private fun VersionTab(
    index: Int,
    timestamp: Long,
    isSelected: Boolean,
    isLatest: Boolean,
    onClick: () -> Unit
) {
    val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
    val timeString = timeFormat.format(Date(timestamp))

    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(6.dp))
            .background(
                if (isSelected) Accent.copy(alpha = 0.15f) else Card
            )
            .border(
                width = 1.dp,
                color = if (isSelected) Accent.copy(alpha = 0.5f) else Border,
                shape = RoundedCornerShape(6.dp)
            )
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text(
            text = "v${index + 1}",
            color = if (isSelected) Accent else TextSecondary,
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold
        )

        Text(
            text = "·",
            color = TextTertiary,
            fontSize = 11.sp
        )

        Text(
            text = timeString,
            color = if (isSelected) Accent else TextSecondary,
            fontSize = 10.sp
        )

        if (isLatest) {
            Text(
                text = "(latest)",
                color = TextTertiary,
                fontSize = 9.sp
            )
        }
    }
}
