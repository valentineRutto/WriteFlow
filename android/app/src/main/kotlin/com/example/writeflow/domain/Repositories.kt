package com.example.writeflow.domain

interface ScanRepository {
    suspend fun scan(documentType: DocumentType, batchMode: Boolean): ScannedDocument
    suspend fun cleanText(text: String): String
}

interface LibraryRepository {
    suspend fun documents(): List<LibraryDocument>
}
