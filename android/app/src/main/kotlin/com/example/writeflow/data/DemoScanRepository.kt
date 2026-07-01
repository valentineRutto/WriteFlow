package com.example.writeflow.data

import com.example.writeflow.domain.DocumentType
import com.example.writeflow.domain.ScanRepository
import com.example.writeflow.domain.ScannedDocument
import com.example.writeflow.domain.ScannedPage
import kotlinx.coroutines.delay

class DemoScanRepository : ScanRepository {
    override suspend fun scan(
        documentType: DocumentType,
        batchMode: Boolean,
    ): ScannedDocument {
        delay(350)

        val pageCount = if (batchMode) 3 else 1
        val pages = List(pageCount) { index ->
            val text = cleanText(
                """
                March 14th, 1987
                The morning light came through the curtains differently today. I sat with my tea
                and watched the garden wake up slowly, each leaf catching what little warmth
                there was. Mother called from Nakuru - she sounds well.
                """.trimIndent(),
            )

            ScannedPage(
                number = index + 1,
                text = text,
                confidence = 0.94 - (index * 0.01),
                lowConfidencePhrases = listOf("March 14th, 1987", "Mother called"),
                aiEngine = "Local OCR cleanup",
            )
        }

        return ScannedDocument(
            title = documentType.title.substringBefore(" /").ifBlank { "Scanned document" },
            pages = pages,
            engine = "Native demo scanner",
        )
    }

    override suspend fun cleanText(text: String): String {
        delay(150)

        return text
            .lines()
            .map { line -> line.trim().replace(Regex("\\s+"), " ") }
            .filter { line -> line.isNotBlank() }
            .joinToString("\n")
            .replace(" ,", ",")
            .replace(" .", ".")
            .replace(" ?", "?")
            .replace(" !", "!")
            .replace(Regex("(^|[.!?]\\s+)([a-z])")) { match ->
                match.groupValues[1] + match.groupValues[2].uppercase()
            }
    }
}
