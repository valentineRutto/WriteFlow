package com.example.writeflow.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.writeflow.domain.AppScreen
import com.example.writeflow.domain.DocumentColor
import com.example.writeflow.domain.DocumentIcon
import com.example.writeflow.domain.DocumentType
import com.example.writeflow.domain.ExportType
import com.example.writeflow.domain.LibraryDocument
import com.example.writeflow.domain.LibraryRepository
import com.example.writeflow.domain.ScanRepository
import com.example.writeflow.domain.ScannedDocument
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class WriteFlowUiState(
    val screen: AppScreen = AppScreen.Home,
    val documentTypes: List<DocumentType> = defaultDocumentTypes,
    val selectedDocumentTypeIndex: Int = 0,
    val batchMode: Boolean = false,
    val isScanning: Boolean = false,
    val scanError: String? = null,
    val document: ScannedDocument? = null,
    val selectedPageIndex: Int = 0,
    val selectedExportIndex: Int = 0,
    val isCleaningText: Boolean = false,
    val libraryDocuments: List<LibraryDocument> = emptyList(),
    val libraryQuery: String = "",
)

val WriteFlowUiState.selectedDocumentType: DocumentType
    get() = documentTypes.getOrElse(selectedDocumentTypeIndex) { documentTypes.first() }

val WriteFlowUiState.filteredLibraryDocuments: List<LibraryDocument>
    get() {
        val query = libraryQuery.trim().lowercase()
        if (query.isBlank()) return libraryDocuments

        return libraryDocuments.filter { document ->
            document.title.lowercase().contains(query) ||
                document.category.lowercase().contains(query)
        }
    }

val WriteFlowUiState.currentPage
    get() = document?.pages?.getOrNull(selectedPageIndex)

val exportTypes = listOf(
    ExportType("PDF", DocumentIcon.Business, DocumentColor.Red),
    ExportType("EPUB", DocumentIcon.Letter, DocumentColor.Blue),
    ExportType("eBook", DocumentIcon.Study, DocumentColor.Brown),
)

val defaultDocumentTypes = listOf(
    DocumentType(
        title = "Diary / journal",
        subtitle = "Personal entries",
        icon = DocumentIcon.Journal,
        color = DocumentColor.Green,
    ),
    DocumentType(
        title = "Poetry",
        subtitle = "Verses & stanzas",
        icon = DocumentIcon.Poetry,
        color = DocumentColor.Blue,
    ),
    DocumentType(
        title = "Meeting notes",
        subtitle = "Minutes & actions",
        icon = DocumentIcon.Notes,
        color = DocumentColor.Brown,
    ),
    DocumentType(
        title = "Class notes",
        subtitle = "Lectures & study",
        icon = DocumentIcon.Study,
        color = DocumentColor.Leaf,
    ),
    DocumentType(
        title = "Recipes",
        subtitle = "Ingredients & steps",
        icon = DocumentIcon.Recipe,
        color = DocumentColor.Rust,
    ),
    DocumentType(
        title = "Sermon",
        subtitle = "Notes & scripture",
        icon = DocumentIcon.Sermon,
        color = DocumentColor.Purple,
    ),
)

class WriteFlowViewModel(
    private val scanRepository: ScanRepository,
    private val libraryRepository: LibraryRepository,
) : ViewModel() {
    private val _uiState = MutableStateFlow(WriteFlowUiState())
    val uiState: StateFlow<WriteFlowUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            _uiState.update { state ->
                state.copy(libraryDocuments = libraryRepository.documents())
            }
        }
    }

    fun selectScreen(screen: AppScreen) {
        _uiState.update { it.copy(screen = screen) }
    }

    fun showHome() {
        selectScreen(AppScreen.Home)
    }

    fun selectDocumentType(index: Int) {
        _uiState.update { state ->
            if (index !in state.documentTypes.indices) state
            else state.copy(selectedDocumentTypeIndex = index)
        }
    }

    fun addDocumentType(documentType: DocumentType) {
        _uiState.update { state ->
            state.copy(
                documentTypes = state.documentTypes + documentType,
                selectedDocumentTypeIndex = state.documentTypes.size,
            )
        }
    }

    fun updateSelectedDocumentType(documentType: DocumentType) {
        _uiState.update { state ->
            val types = state.documentTypes.toMutableList()
            if (state.selectedDocumentTypeIndex !in types.indices) return@update state
            types[state.selectedDocumentTypeIndex] = documentType
            state.copy(documentTypes = types)
        }
    }

    fun setBatchMode(enabled: Boolean) {
        _uiState.update { it.copy(batchMode = enabled) }
    }

    fun scan() {
        val currentState = _uiState.value
        viewModelScope.launch {
            _uiState.update { it.copy(isScanning = true, scanError = null) }

            runCatching {
                scanRepository.scan(
                    documentType = currentState.selectedDocumentType,
                    batchMode = currentState.batchMode,
                )
            }.onSuccess { document ->
                _uiState.update {
                    it.copy(
                        document = document,
                        selectedPageIndex = 0,
                        isScanning = false,
                        screen = AppScreen.Preview,
                    )
                }
            }.onFailure { error ->
                _uiState.update {
                    it.copy(
                        isScanning = false,
                        scanError = error.localizedMessage ?: "Scan failed.",
                    )
                }
            }
        }
    }

    fun selectPreviewPage(index: Int) {
        _uiState.update { state ->
            val pages = state.document?.pages.orEmpty()
            if (index !in pages.indices) state else state.copy(selectedPageIndex = index)
        }
    }

    fun updateCurrentPageText(text: String) {
        _uiState.update { state ->
            val document = state.document ?: return@update state
            val pages = document.pages.toMutableList()
            val page = pages.getOrNull(state.selectedPageIndex) ?: return@update state
            pages[state.selectedPageIndex] = page.copy(text = text)
            state.copy(document = document.copy(pages = pages))
        }
    }

    fun cleanCurrentPage() {
        val page = _uiState.value.currentPage ?: return
        viewModelScope.launch {
            _uiState.update { it.copy(isCleaningText = true) }
            val cleanedText = scanRepository.cleanText(page.text)
            updateCurrentPageText(cleanedText)
            _uiState.update { it.copy(isCleaningText = false) }
        }
    }

    fun selectExportType(index: Int) {
        if (index !in exportTypes.indices) return
        _uiState.update { it.copy(selectedExportIndex = index) }
    }

    fun searchLibrary(query: String) {
        _uiState.update { it.copy(libraryQuery = query) }
    }
}
