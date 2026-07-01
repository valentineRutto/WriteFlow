package com.example.writeflow.presentation

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.AutoFixHigh
import androidx.compose.material.icons.outlined.Book
import androidx.compose.material.icons.outlined.BusinessCenter
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Church
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.DocumentScanner
import androidx.compose.material.icons.outlined.Draw
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.Folder
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.MenuBook
import androidx.compose.material.icons.outlined.Notes
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.PictureAsPdf
import androidx.compose.material.icons.outlined.RestaurantMenu
import androidx.compose.material.icons.outlined.School
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilledTonalIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.writeflow.domain.AppScreen
import com.example.writeflow.domain.DocumentColor
import com.example.writeflow.domain.DocumentIcon
import com.example.writeflow.domain.DocumentType
import com.example.writeflow.domain.LibraryDocument
import com.example.writeflow.domain.ScannedPage
import com.example.writeflow.presentation.theme.AccentGreen
import com.example.writeflow.presentation.theme.Border
import com.example.writeflow.presentation.theme.BorderLight
import com.example.writeflow.presentation.theme.BrownText
import com.example.writeflow.presentation.theme.Canvas
import com.example.writeflow.presentation.theme.DarkMintText
import com.example.writeflow.presentation.theme.DeepGreen
import com.example.writeflow.presentation.theme.Mint
import com.example.writeflow.presentation.theme.ScanLine
import com.example.writeflow.presentation.theme.Shell
import com.example.writeflow.presentation.theme.Surface
import com.example.writeflow.presentation.theme.TextFaint
import com.example.writeflow.presentation.theme.TextMuted
import com.example.writeflow.presentation.theme.TextPrimary
import com.example.writeflow.presentation.theme.WarmHighlight
import com.example.writeflow.presentation.viewmodel.WriteFlowUiState
import com.example.writeflow.presentation.viewmodel.currentPage
import com.example.writeflow.presentation.viewmodel.exportTypes
import com.example.writeflow.presentation.viewmodel.filteredLibraryDocuments

@Composable
fun WriteFlowApp(
    state: WriteFlowUiState,
    onScreenSelected: (AppScreen) -> Unit,
    onDocumentTypeSelected: (Int) -> Unit,
    onAddDocumentType: (DocumentType) -> Unit,
    onUpdateDocumentType: (DocumentType) -> Unit,
    onBatchModeChanged: (Boolean) -> Unit,
    onScan: () -> Unit,
    onAddPage: () -> Unit,
    onPreviewPageSelected: (Int) -> Unit,
    onRecognizedTextChanged: (String) -> Unit,
    onCleanText: () -> Unit,
    onExportSelected: (Int) -> Unit,
    onSearchChanged: (String) -> Unit,
) {
    Scaffold(
        containerColor = Shell,
        bottomBar = {
            AppNavBar(
                current = state.screen,
                onHome = { onScreenSelected(AppScreen.Home) },
                onLibrary = { onScreenSelected(AppScreen.Library) },
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp, vertical = 10.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = "INKSCRIBE - HANDWRITTEN TO DIGITAL",
                color = TextMuted,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
            )
            Spacer(Modifier.height(12.dp))
            ScreenTabs(state.screen, onScreenSelected)
            Spacer(Modifier.height(12.dp))

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .clip(RoundedCornerShape(32.dp))
                    .background(Canvas)
                    .border(1.dp, Border, RoundedCornerShape(32.dp)),
            ) {
                when (state.screen) {
                    AppScreen.Home -> HomeScreen(
                        state = state,
                        onDocumentTypeSelected = onDocumentTypeSelected,
                        onAddDocumentType = onAddDocumentType,
                        onUpdateDocumentType = onUpdateDocumentType,
                        onBatchModeChanged = onBatchModeChanged,
                        onScan = onScan,
                    )

                    AppScreen.Preview -> PreviewScreen(
                        state = state,
                        onBack = { onScreenSelected(AppScreen.Home) },
                        onAddPage = onAddPage,
                        onPreviewPageSelected = onPreviewPageSelected,
                        onRecognizedTextChanged = onRecognizedTextChanged,
                        onCleanText = onCleanText,
                        onExportSelected = onExportSelected,
                    )

                    AppScreen.Library -> LibraryScreen(
                        state = state,
                        onSearchChanged = onSearchChanged,
                    )
                }
            }
        }
    }
}

@Composable
private fun HomeScreen(
    state: WriteFlowUiState,
    onDocumentTypeSelected: (Int) -> Unit,
    onAddDocumentType: (DocumentType) -> Unit,
    onUpdateDocumentType: (DocumentType) -> Unit,
    onBatchModeChanged: (Boolean) -> Unit,
    onScan: () -> Unit,
) {
    var editorMode by remember { mutableStateOf<DocumentTypeEditorMode?>(null) }

    editorMode?.let { mode ->
        DocumentTypeDialog(
            initialType = mode.initialType,
            title = mode.title,
            onDismiss = { editorMode = null },
            onSave = { documentType ->
                when (mode) {
                    is DocumentTypeEditorMode.Add -> onAddDocumentType(documentType)
                    is DocumentTypeEditorMode.Edit -> onUpdateDocumentType(documentType)
                }
                editorMode = null
            },
        )
    }

    LazyColumn(
        contentPadding = PaddingValues(bottom = 18.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        item {
            AppTopBar(
                title = "Inkscribe",
                subtitle = "On-device AI - no internet needed",
                icon = Icons.Outlined.Notifications,
            )
        }
        item {
            ScanHero(onScan = onScan, isScanning = state.isScanning)
        }
        item {
            SectionHeader(
                label = "Document type",
                actions = {
                    IconButton(
                        onClick = {
                            editorMode = DocumentTypeEditorMode.Edit(
                                state.documentTypes[state.selectedDocumentTypeIndex],
                            )
                        },
                    ) {
                        Icon(Icons.Outlined.Edit, contentDescription = "Edit document type")
                    }
                    FilledTonalIconButton(
                        onClick = { editorMode = DocumentTypeEditorMode.Add },
                    ) {
                        Icon(Icons.Outlined.Add, contentDescription = "Add document type")
                    }
                },
            )
        }
        item {
            DocumentTypeGrid(
                documentTypes = state.documentTypes,
                selectedIndex = state.selectedDocumentTypeIndex,
                onSelected = onDocumentTypeSelected,
            )
        }
        item {
            BatchScanTile(value = state.batchMode, onChanged = onBatchModeChanged)
        }
        item {
            PrimaryScanButton(isScanning = state.isScanning, onClick = onScan)
        }
        state.scanError?.let { error ->
            item {
                Text(
                    text = error,
                    color = Color(0xFFA32D2D),
                    modifier = Modifier.padding(horizontal = 20.dp),
                    fontSize = 12.sp,
                )
            }
        }
    }
}

@Composable
private fun PreviewScreen(
    state: WriteFlowUiState,
    onBack: () -> Unit,
    onAddPage: () -> Unit,
    onPreviewPageSelected: (Int) -> Unit,
    onRecognizedTextChanged: (String) -> Unit,
    onCleanText: () -> Unit,
    onExportSelected: (Int) -> Unit,
) {
    var isEditingText by remember { mutableStateOf(false) }
    val document = state.document
    val pages = document?.pages.orEmpty()
    val selectedExport = exportTypes[state.selectedExportIndex]
    val currentPage = state.currentPage

    if (isEditingText && currentPage != null) {
        RecognizedTextDialog(
            initialText = currentPage.text,
            onDismiss = { isEditingText = false },
            onSave = {
                onRecognizedTextChanged(it)
                isEditingText = false
            },
        )
    }

    LazyColumn(
        contentPadding = PaddingValues(bottom = 18.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            PreviewTopBar(
                title = "${document?.title ?: "Scanned document"} - ${pages.size} page",
                subtitle = "Scanned just now - edge AI processing done",
                onBack = onBack,
                onEdit = { isEditingText = true },
            )
        }
        item {
            LazyRow(
                contentPadding = PaddingValues(horizontal = 20.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                itemsIndexed(pages) { index, _ ->
                    PageThumb(
                        label = "Pg ${index + 1}",
                        active = index == state.selectedPageIndex,
                        onClick = { onPreviewPageSelected(index) },
                    )
                }
                item {
                    PageThumb(
                        label = "Add",
                        icon = Icons.Outlined.Add,
                        active = false,
                        onClick = onAddPage,
                    )
                }
            }
        }
        item {
            OcrPreviewCard(page = state.currentPage)
        }
        item {
            AiPipelineBadge(
                engine = document?.engine ?: "Scanner ready",
                aiEngine = state.currentPage?.aiEngine ?: "Text cleanup ready",
            )
        }
        item {
            AccuracyMeter(confidence = document?.overallConfidence ?: 0.0)
        }
        item {
            Text(
                text = "Export as",
                color = TextPrimary,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(horizontal = 20.dp),
            )
        }
        item {
            Row(
                modifier = Modifier.padding(horizontal = 20.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                exportTypes.forEachIndexed { index, exportType ->
                    ExportOptionCard(
                        exportType = exportType,
                        selected = index == state.selectedExportIndex,
                        onClick = { onExportSelected(index) },
                        modifier = Modifier.weight(1f),
                    )
                }
            }
        }
        item {
            Row(
                modifier = Modifier.padding(horizontal = 20.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                OutlinedButton(onClick = { isEditingText = true }) {
                    Icon(Icons.Outlined.Edit, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(6.dp))
                    Text("Edit text")
                }
                OutlinedButton(onClick = onCleanText, enabled = !state.isCleaningText) {
                    if (state.isCleaningText) {
                        CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
                    } else {
                        Icon(Icons.Outlined.AutoFixHigh, contentDescription = null, modifier = Modifier.size(18.dp))
                    }
                    Spacer(Modifier.width(6.dp))
                    Text("Clean")
                }
                OutlinedButton(onClick = {}, modifier = Modifier.weight(1f)) {
                    Text("Export ${selectedExport.label}")
                }
            }
        }
    }
}

@Composable
private fun LibraryScreen(
    state: WriteFlowUiState,
    onSearchChanged: (String) -> Unit,
) {
    LazyColumn(contentPadding = PaddingValues(bottom = 18.dp)) {
        item {
            AppTopBar(
                title = "My library",
                subtitle = "12 documents - 47 pages",
                icon = Icons.Outlined.Tune,
            )
        }
        item {
            OutlinedTextField(
                value = state.libraryQuery,
                onValueChange = onSearchChanged,
                placeholder = { Text("Search documents...") },
                leadingIcon = { Icon(Icons.Outlined.Search, contentDescription = null) },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 4.dp),
                singleLine = true,
            )
        }
        items(state.filteredLibraryDocuments) { document ->
            LibraryItemTile(
                item = document,
                isLast = document == state.filteredLibraryDocuments.lastOrNull(),
            )
        }
    }
}

@Composable
private fun AppTopBar(title: String, subtitle: String, icon: ImageVector) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(title, color = TextPrimary, fontSize = 18.sp, fontWeight = FontWeight.Bold)
            Text(subtitle, color = TextMuted, fontSize = 12.sp)
        }
        Icon(icon, contentDescription = null, tint = TextMuted)
    }
}

@Composable
private fun ScanHero(onScan: () -> Unit, isScanning: Boolean) {
    Box(
        modifier = Modifier
            .padding(horizontal = 20.dp)
            .fillMaxWidth()
            .height(200.dp)
            .clip(RoundedCornerShape(20.dp))
            .background(DeepGreen)
            .clickable(enabled = !isScanning, onClick = onScan),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            if (isScanning) {
                CircularProgressIndicator(color = Mint)
            } else {
                Icon(
                    Icons.Outlined.DocumentScanner,
                    contentDescription = null,
                    tint = Mint,
                    modifier = Modifier.size(42.dp),
                )
            }
            Spacer(Modifier.height(8.dp))
            Text(
                text = if (isScanning) "Processing scan..." else "Tap to scan",
                color = Mint,
                fontWeight = FontWeight.Bold,
            )
            Text("Position page within frame", color = ScanLine, fontSize = 12.sp)
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun DocumentTypeGrid(
    documentTypes: List<DocumentType>,
    selectedIndex: Int,
    onSelected: (Int) -> Unit,
) {
    FlowRow(
        modifier = Modifier.padding(horizontal = 20.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        maxItemsInEachRow = 2,
    ) {
        documentTypes.forEachIndexed { index, documentType ->
            SelectableCard(
                documentType = documentType,
                selected = index == selectedIndex,
                onClick = { onSelected(index) },
                modifier = Modifier.weight(1f),
            )
        }
    }
}

@Composable
private fun SelectableCard(
    documentType: DocumentType,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val color = documentType.color.toColor()
    Column(
        modifier = modifier
            .height(86.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(if (selected) Mint else Surface)
            .border(
                width = if (selected) 2.dp else 1.dp,
                color = if (selected) AccentGreen else BorderLight,
                shape = RoundedCornerShape(12.dp),
            )
            .clickable(onClick = onClick)
            .padding(10.dp),
        verticalArrangement = Arrangement.Center,
    ) {
        Icon(documentType.icon.toIcon(), contentDescription = null, tint = color)
        Text(
            text = documentType.title,
            color = TextPrimary,
            fontSize = 13.sp,
            fontWeight = FontWeight.Bold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            text = documentType.subtitle,
            color = TextMuted,
            fontSize = 11.sp,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
private fun BatchScanTile(value: Boolean, onChanged: (Boolean) -> Unit) {
    Row(
        modifier = Modifier
            .padding(horizontal = 20.dp)
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(Surface)
            .border(1.dp, BorderLight, RoundedCornerShape(12.dp))
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text("Batch scan mode", color = TextPrimary, fontSize = 13.sp, fontWeight = FontWeight.Bold)
            Text("Scan multiple pages in one session", color = TextMuted, fontSize = 11.sp)
        }
        Switch(checked = value, onCheckedChange = onChanged)
    }
}

@Composable
private fun PrimaryScanButton(isScanning: Boolean, onClick: () -> Unit) {
    OutlinedButton(
        onClick = onClick,
        enabled = !isScanning,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp),
        colors = ButtonDefaults.outlinedButtonColors(
            containerColor = DeepGreen,
            contentColor = Mint,
        ),
        border = BorderStroke(0.dp, DeepGreen),
        shape = RoundedCornerShape(14.dp),
    ) {
        Icon(Icons.Outlined.DocumentScanner, contentDescription = null)
        Spacer(Modifier.width(8.dp))
        Text(if (isScanning) "Processing scan..." else "Open camera scanner")
    }
}

@Composable
private fun PreviewTopBar(
    title: String,
    subtitle: String,
    onBack: () -> Unit,
    onEdit: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, BorderLight)
            .padding(horizontal = 8.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconButton(onClick = onBack) {
            Icon(Icons.Outlined.Close, contentDescription = "Back")
        }
        Column(modifier = Modifier.weight(1f)) {
            Text(title, color = TextPrimary, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            Text(subtitle, color = TextMuted, fontSize = 11.sp)
        }
        IconButton(onClick = onEdit) {
            Icon(Icons.Outlined.Edit, contentDescription = "Edit text")
        }
    }
}

@Composable
private fun PageThumb(
    label: String,
    active: Boolean,
    onClick: () -> Unit,
    icon: ImageVector = Icons.Outlined.Description,
) {
    Column(
        modifier = Modifier
            .size(width = 64.dp, height = 84.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(Surface)
            .border(
                width = if (active) 2.dp else 1.dp,
                color = if (active) AccentGreen else BorderLight,
                shape = RoundedCornerShape(8.dp),
            )
            .clickable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Icon(icon, contentDescription = null, tint = TextMuted)
        Text(label, color = TextMuted, fontSize = 10.sp)
    }
}

@Composable
private fun OcrPreviewCard(page: ScannedPage?) {
    Column(
        modifier = Modifier
            .padding(horizontal = 20.dp)
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(Surface)
            .border(1.dp, BorderLight, RoundedCornerShape(12.dp))
            .padding(14.dp),
    ) {
        Text(
            text = "Recognised text - page ${page?.number ?: 1}",
            color = TextMuted,
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            text = page?.text ?: "No recognized text yet.",
            color = TextPrimary,
            fontSize = 13.sp,
            lineHeight = 21.sp,
            fontFamily = FontFamily.Serif,
        )
    }
}

@Composable
private fun AiPipelineBadge(engine: String, aiEngine: String) {
    Text(
        text = "$engine\n$aiEngine",
        color = DarkMintText,
        fontSize = 10.sp,
        fontWeight = FontWeight.Bold,
        modifier = Modifier
            .padding(horizontal = 20.dp)
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(Mint)
            .border(1.dp, AccentGreen.copy(alpha = 0.3f), RoundedCornerShape(12.dp))
            .padding(12.dp),
    )
}

@Composable
private fun AccuracyMeter(confidence: Double) {
    Row(
        modifier = Modifier.padding(horizontal = 20.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text("Overall accuracy", color = TextMuted, fontSize = 11.sp)
        Spacer(Modifier.width(8.dp))
        LinearProgressIndicator(
            progress = { confidence.toFloat() },
            modifier = Modifier.weight(1f),
            color = AccentGreen,
            trackColor = BorderLight,
        )
        Spacer(Modifier.width(8.dp))
        Text("${(confidence * 100).toInt()}%", color = DeepGreen, fontSize = 11.sp)
    }
}

@Composable
private fun ExportOptionCard(
    exportType: com.example.writeflow.domain.ExportType,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .height(72.dp)
            .clip(RoundedCornerShape(10.dp))
            .background(if (selected) Mint else Surface)
            .border(
                width = if (selected) 2.dp else 1.dp,
                color = if (selected) AccentGreen else BorderLight,
                shape = RoundedCornerShape(10.dp),
            )
            .clickable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Icon(exportType.icon.toExportIcon(), contentDescription = null, tint = exportType.color.toColor())
        Text(exportType.label, color = exportType.color.toColor(), fontSize = 11.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun LibraryItemTile(item: LibraryDocument, isLast: Boolean) {
    val color = categoryColor(item.category)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .border(if (isLast) 0.dp else 1.dp, if (isLast) Color.Transparent else BorderLight)
            .padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(color.copy(alpha = 0.14f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(categoryIcon(item.category), contentDescription = null, tint = color)
        }
        Spacer(Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(item.title, color = TextPrimary, fontSize = 14.sp, fontWeight = FontWeight.Bold)
            Text(item.meta, color = TextMuted, fontSize = 11.sp)
        }
        Text(
            text = item.category,
            color = color,
            fontSize = 10.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier
                .clip(CircleShape)
                .background(color.copy(alpha = 0.14f))
                .padding(horizontal = 8.dp, vertical = 3.dp),
        )
    }
}

@Composable
private fun AppNavBar(current: AppScreen, onHome: () -> Unit, onLibrary: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Canvas)
            .border(1.dp, BorderLight)
            .padding(vertical = 8.dp),
    ) {
        NavItem(Icons.Outlined.Home, "Scan", current == AppScreen.Home, onHome, Modifier.weight(1f))
        NavItem(Icons.Outlined.Folder, "Library", current == AppScreen.Library, onLibrary, Modifier.weight(1f))
        NavItem(Icons.Outlined.Settings, "Settings", false, {}, Modifier.weight(1f))
    }
}

@Composable
private fun NavItem(
    icon: ImageVector,
    label: String,
    active: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val color = if (active) DeepGreen else TextFaint
    Column(
        modifier = modifier.clickable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(icon, contentDescription = label, tint = color, modifier = Modifier.size(21.dp))
        Text(label, color = color, fontSize = 10.sp, fontWeight = if (active) FontWeight.Bold else FontWeight.Medium)
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ScreenTabs(screen: AppScreen, onSelected: (AppScreen) -> Unit) {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        TabPill("Home", screen == AppScreen.Home) { onSelected(AppScreen.Home) }
        TabPill("Preview & export", screen == AppScreen.Preview) { onSelected(AppScreen.Preview) }
        TabPill("My library", screen == AppScreen.Library) { onSelected(AppScreen.Library) }
    }
}

@Composable
private fun TabPill(label: String, selected: Boolean, onClick: () -> Unit) {
    OutlinedButton(
        onClick = onClick,
        colors = ButtonDefaults.outlinedButtonColors(
            containerColor = if (selected) DeepGreen else Surface,
            contentColor = if (selected) Mint else TextMuted,
        ),
        border = BorderStroke(1.dp, Border),
        contentPadding = PaddingValues(horizontal = 14.dp, vertical = 6.dp),
    ) {
        Text(label, fontSize = 12.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun SectionHeader(
    label: String,
    actions: @Composable () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = label.uppercase(),
            color = TextMuted,
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.weight(1f),
        )
        actions()
    }
}

@Composable
private fun DocumentTypeDialog(
    initialType: DocumentType?,
    title: String,
    onDismiss: () -> Unit,
    onSave: (DocumentType) -> Unit,
) {
    var name by remember(initialType) { mutableStateOf(initialType?.title.orEmpty()) }
    var subtitle by remember(initialType) { mutableStateOf(initialType?.subtitle.orEmpty()) }
    var icon by remember(initialType) { mutableStateOf(initialType?.icon ?: DocumentIcon.Journal) }
    var color by remember(initialType) { mutableStateOf(initialType?.color ?: DocumentColor.Green) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            LazyColumn(
                modifier = Modifier.heightIn(max = 520.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                item {
                    OutlinedTextField(
                        value = name,
                        onValueChange = { name = it },
                        label = { Text("Name") },
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next),
                    )
                }
                item {
                    OutlinedTextField(
                        value = subtitle,
                        onValueChange = { subtitle = it },
                        label = { Text("Subtitle") },
                        singleLine = true,
                        keyboardActions = KeyboardActions(onDone = {
                            saveDocumentType(name, subtitle, icon, color, onSave)
                        }),
                    )
                }
                item {
                    PickerLabel("Icon")
                    OptionGrid(DocumentIcon.entries, icon, { it.toIcon() }) { icon = it }
                }
                item {
                    PickerLabel("Color")
                    ColorGrid(DocumentColor.entries, color) { color = it }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = { saveDocumentType(name, subtitle, icon, color, onSave) },
            ) {
                Text("Save")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        },
    )
}

@Composable
private fun RecognizedTextDialog(
    initialText: String,
    onDismiss: () -> Unit,
    onSave: (String) -> Unit,
) {
    var text by remember(initialText) { mutableStateOf(initialText) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Edit recognised text") },
        text = {
            OutlinedTextField(
                value = text,
                onValueChange = { text = it },
                modifier = Modifier.height(220.dp),
                minLines = 6,
                label = { Text("Recognised text") },
            )
        },
        confirmButton = {
            TextButton(onClick = { onSave(text) }) {
                Text("Save")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        },
    )
}

@Composable
private fun PickerLabel(text: String) {
    Text(text, color = TextPrimary, fontWeight = FontWeight.Bold)
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun <T> OptionGrid(
    values: List<T>,
    selected: T,
    icon: (T) -> ImageVector,
    onSelected: (T) -> Unit,
) {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        values.forEach { value ->
            FilledTonalIconButton(onClick = { onSelected(value) }) {
                Icon(icon(value), contentDescription = value.toString(), tint = if (value == selected) DeepGreen else TextMuted)
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ColorGrid(
    values: List<DocumentColor>,
    selected: DocumentColor,
    onSelected: (DocumentColor) -> Unit,
) {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        values.forEach { value ->
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(value.toColor())
                    .border(
                        width = if (value == selected) 3.dp else 1.dp,
                        color = if (value == selected) TextPrimary else BorderLight,
                        shape = CircleShape,
                    )
                    .clickable { onSelected(value) },
                contentAlignment = Alignment.Center,
            ) {
                if (value == selected) {
                    Icon(Icons.Outlined.Check, contentDescription = null, tint = Color.White)
                }
            }
        }
    }
}

private sealed class DocumentTypeEditorMode {
    abstract val initialType: DocumentType?
    abstract val title: String

    data object Add : DocumentTypeEditorMode() {
        override val initialType: DocumentType? = null
        override val title: String = "Add document type"
    }

    data class Edit(override val initialType: DocumentType) : DocumentTypeEditorMode() {
        override val title: String = "Edit document type"
    }
}

private fun saveDocumentType(
    name: String,
    subtitle: String,
    icon: DocumentIcon,
    color: DocumentColor,
    onSave: (DocumentType) -> Unit,
) {
    val trimmedName = name.trim()
    val trimmedSubtitle = subtitle.trim()
    if (trimmedName.isBlank() || trimmedSubtitle.isBlank()) return
    onSave(DocumentType(trimmedName, trimmedSubtitle, icon, color))
}

private fun DocumentIcon.toIcon(): ImageVector = when (this) {
    DocumentIcon.Journal -> Icons.Outlined.MenuBook
    DocumentIcon.Poetry -> Icons.Outlined.Draw
    DocumentIcon.Notes -> Icons.Outlined.Notes
    DocumentIcon.Study -> Icons.Outlined.School
    DocumentIcon.Recipe -> Icons.Outlined.RestaurantMenu
    DocumentIcon.Sermon -> Icons.Outlined.Church
    DocumentIcon.Business -> Icons.Outlined.BusinessCenter
    DocumentIcon.Letter -> Icons.Outlined.Description
}

private fun DocumentIcon.toExportIcon(): ImageVector = when (this) {
    DocumentIcon.Business -> Icons.Outlined.PictureAsPdf
    DocumentIcon.Letter -> Icons.Outlined.Book
    else -> toIcon()
}

private fun DocumentColor.toColor(): Color = when (this) {
    DocumentColor.Green -> DeepGreen
    DocumentColor.Blue -> Color(0xFF185FA5)
    DocumentColor.Brown -> BrownText
    DocumentColor.Leaf -> Color(0xFF3B6D11)
    DocumentColor.Rust -> Color(0xFF993C1D)
    DocumentColor.Purple -> Color(0xFF534AB7)
    DocumentColor.Red -> Color(0xFFA32D2D)
    DocumentColor.Slate -> Color(0xFF444441)
}

private fun categoryColor(category: String): Color = when (category) {
    "Diary" -> DeepGreen
    "Poetry" -> Color(0xFF185FA5)
    "Recipe" -> BrownText
    "Sermon" -> Color(0xFF534AB7)
    "Notes" -> Color(0xFF3B6D11)
    else -> Color(0xFF444441)
}

private fun categoryIcon(category: String): ImageVector = when (category) {
    "Diary" -> Icons.Outlined.MenuBook
    "Poetry" -> Icons.Outlined.Draw
    "Recipe" -> Icons.Outlined.RestaurantMenu
    "Sermon" -> Icons.Outlined.Church
    "Notes" -> Icons.Outlined.School
    else -> Icons.Outlined.BusinessCenter
}
