package com.example.writeflow.domain

enum class AppScreen {
    Home,
    Preview,
    Library,
}

enum class DocumentIcon {
    Journal,
    Poetry,
    Notes,
    Study,
    Recipe,
    Sermon,
    Business,
    Letter,
}

enum class DocumentColor {
    Green,
    Blue,
    Brown,
    Leaf,
    Rust,
    Purple,
    Red,
    Slate,
}

data class DocumentType(
    val title: String,
    val subtitle: String,
    val icon: DocumentIcon,
    val color: DocumentColor,
)

data class ScannedPage(
    val number: Int,
    val text: String,
    val confidence: Double,
    val lowConfidencePhrases: List<String>,
    val aiEngine: String,
)

data class ScannedDocument(
    val title: String,
    val pages: List<ScannedPage>,
    val engine: String,
) {
    val overallConfidence: Double
        get() = pages.map { it.confidence }.average().takeIf { !it.isNaN() } ?: 0.0
}

data class LibraryDocument(
    val title: String,
    val meta: String,
    val category: String,
)

data class ExportType(
    val label: String,
    val icon: DocumentIcon,
    val color: DocumentColor,
)
