package com.example.writeflow.data

import com.example.writeflow.domain.LibraryDocument
import com.example.writeflow.domain.LibraryRepository

class DemoLibraryRepository : LibraryRepository {
    override suspend fun documents(): List<LibraryDocument> {
        return listOf(
            LibraryDocument(
                title = "Diary - March 1987",
                meta = "3 pages - PDF - Today",
                category = "Diary",
            ),
            LibraryDocument(
                title = "Poems - untitled collection",
                meta = "8 pages - EPUB - Yesterday",
                category = "Poetry",
            ),
            LibraryDocument(
                title = "Grandma's recipe book",
                meta = "14 pages - eBook - Jun 8",
                category = "Recipe",
            ),
            LibraryDocument(
                title = "Sunday sermon notes",
                meta = "5 pages - PDF - Jun 2",
                category = "Sermon",
            ),
            LibraryDocument(
                title = "Biology - cell division",
                meta = "6 pages - PDF - May 29",
                category = "Notes",
            ),
            LibraryDocument(
                title = "Q1 business ledger",
                meta = "11 pages - PDF - May 15",
                category = "Business",
            ),
        )
    }
}
