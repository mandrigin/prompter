package com.prompter.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.prompter.db.GenerationStatus
import com.prompter.db.PromptHistoryWithVersions
import com.prompter.ui.theme.*
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun HistoryDrawer(
    history: List<PromptHistoryWithVersions>,
    selectedId: String?,
    generatingIds: Set<String>,
    onSelect: (PromptHistoryWithVersions) -> Unit,
    onDelete: (PromptHistoryWithVersions) -> Unit,
    onArchive: (PromptHistoryWithVersions) -> Unit,
    onCreate: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxHeight()
            .background(Surface)
            .padding(8.dp)
    ) {
        // Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                "History",
                color = TextPrimary,
                fontWeight = FontWeight.SemiBold,
                fontSize = 16.sp
            )
            IconButton(onClick = onCreate) {
                Icon(
                    Icons.Default.Add,
                    contentDescription = "New prompt",
                    tint = Accent
                )
            }
        }

        Divider(color = Separator, thickness = 1.dp)

        // Group history by date
        val groupedHistory = remember(history) {
            groupHistoryByDate(history)
        }

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            groupedHistory.forEach { (dateGroup, items) ->
                item {
                    Text(
                        text = dateGroup,
                        color = TextTertiary,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium,
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)
                    )
                }

                items(items, key = { it.history.id }) { item ->
                    HistoryItem(
                        item = item,
                        isSelected = item.history.id == selectedId,
                        isGenerating = generatingIds.contains(item.history.id),
                        onSelect = { onSelect(item) },
                        onDelete = { onDelete(item) },
                        onArchive = { onArchive(item) }
                    )
                }
            }
        }
    }
}

@Composable
private fun HistoryItem(
    item: PromptHistoryWithVersions,
    isSelected: Boolean,
    isGenerating: Boolean,
    onSelect: () -> Unit,
    onDelete: () -> Unit,
    onArchive: () -> Unit
) {
    var showMenu by remember { mutableStateOf(false) }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(if (isSelected) Accent.copy(alpha = 0.15f) else Color.Transparent)
            .clickable(onClick = onSelect)
            .padding(12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Status indicator
            if (isGenerating) {
                CircularProgressIndicator(
                    modifier = Modifier.size(12.dp),
                    color = Accent,
                    strokeWidth = 2.dp
                )
            } else {
                val statusColor = when (GenerationStatus.fromString(item.history.generationStatus)) {
                    GenerationStatus.COMPLETED -> Success
                    GenerationStatus.FAILED -> Error
                    else -> TextTertiary
                }
                Box(
                    modifier = Modifier
                        .size(8.dp)
                        .clip(RoundedCornerShape(4.dp))
                        .background(statusColor)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Content
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = item.history.prompt,
                    color = if (isSelected) TextPrimary else TextSecondary,
                    fontSize = 13.sp,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                if (item.versions.isNotEmpty()) {
                    Text(
                        text = "${item.versions.size} version${if (item.versions.size > 1) "s" else ""}",
                        color = TextTertiary,
                        fontSize = 11.sp
                    )
                }
            }

            // Menu button
            Box {
                IconButton(
                    onClick = { showMenu = true },
                    modifier = Modifier.size(24.dp)
                ) {
                    Icon(
                        Icons.Default.MoreVert,
                        contentDescription = "More",
                        tint = TextTertiary,
                        modifier = Modifier.size(16.dp)
                    )
                }

                DropdownMenu(
                    expanded = showMenu,
                    onDismissRequest = { showMenu = false }
                ) {
                    DropdownMenuItem(
                        text = { Text("Archive") },
                        onClick = {
                            showMenu = false
                            onArchive()
                        },
                        leadingIcon = {
                            Icon(Icons.Default.Archive, contentDescription = null)
                        }
                    )
                    DropdownMenuItem(
                        text = { Text("Delete", color = Error) },
                        onClick = {
                            showMenu = false
                            onDelete()
                        },
                        leadingIcon = {
                            Icon(Icons.Default.Delete, contentDescription = null, tint = Error)
                        }
                    )
                }
            }
        }
    }
}

private fun groupHistoryByDate(history: List<PromptHistoryWithVersions>): List<Pair<String, List<PromptHistoryWithVersions>>> {
    val now = Calendar.getInstance()
    val today = now.get(Calendar.DAY_OF_YEAR)
    val thisYear = now.get(Calendar.YEAR)

    val groups = mutableMapOf<String, MutableList<PromptHistoryWithVersions>>()

    history.forEach { item ->
        val itemCal = Calendar.getInstance().apply { timeInMillis = item.history.timestamp }
        val itemDay = itemCal.get(Calendar.DAY_OF_YEAR)
        val itemYear = itemCal.get(Calendar.YEAR)

        val group = when {
            itemYear == thisYear && itemDay == today -> "Today"
            itemYear == thisYear && itemDay == today - 1 -> "Yesterday"
            itemYear == thisYear && itemDay > today - 7 -> "This Week"
            itemYear == thisYear -> "This Month"
            else -> SimpleDateFormat("MMMM yyyy", Locale.getDefault()).format(Date(item.history.timestamp))
        }

        groups.getOrPut(group) { mutableListOf() }.add(item)
    }

    // Return in desired order
    val orderedGroups = listOf("Today", "Yesterday", "This Week", "This Month")
    return buildList {
        orderedGroups.forEach { key ->
            groups[key]?.let { add(key to it) }
        }
        // Add remaining groups (older months)
        groups.keys.filter { it !in orderedGroups }.sorted().forEach { key ->
            groups[key]?.let { add(key to it) }
        }
    }
}
