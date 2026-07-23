package com.valentinerutto.inkdoc

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.app.ActivityManager
import android.os.Build
import android.os.StatFs
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "inkdoc/on_device_ai"
    private val scanRequestCode = 9301
    private val executor = Executors.newSingleThreadExecutor()
    private var pendingScanResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanDocument" -> scanDocument(call, result)
                "getDeviceCapabilities" -> result.success(deviceCapabilities())
                "improveText" -> {
                    val text = call.argument<String>("text").orEmpty()
                    result.success(cleanRecognizedText(text))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun deviceCapabilities(): Map<String, Any> {
        val memoryInfo = ActivityManager.MemoryInfo()
        (getSystemService(ACTIVITY_SERVICE) as ActivityManager).getMemoryInfo(memoryInfo)
        val stat = StatFs(filesDir.absolutePath)
        val bytesPerGb = 1024.0 * 1024.0 * 1024.0
        return mapOf(
            "platform" to "Android",
            "osVersion" to "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})",
            "totalRamGb" to memoryInfo.totalMem / bytesPerGb,
            "freeStorageGb" to stat.availableBytes / bytesPerGb,
            "architecture" to Build.SUPPORTED_ABIS.firstOrNull().orEmpty(),
            "isSimulator" to (
                Build.FINGERPRINT.contains("generic") ||
                    Build.MODEL.contains("Emulator") ||
                    Build.MODEL.contains("sdk_gphone")
                ),
        )
    }

    private fun scanDocument(call: MethodCall, result: MethodChannel.Result) {
        if (pendingScanResult != null) {
            result.error("SCAN_IN_PROGRESS", "A document scan is already running.", null)
            return
        }

        pendingScanResult = result

        val batchMode = call.argument<Boolean>("batchMode") ?: false
        val requestedPageLimit = call.argument<Int>("pageLimit") ?: 1
        val pageLimit = if (batchMode) requestedPageLimit.coerceIn(2, 10) else 1
        val options = GmsDocumentScannerOptions.Builder()
            .setGalleryImportAllowed(false)
            .setPageLimit(pageLimit)
            .setResultFormats(
                GmsDocumentScannerOptions.RESULT_FORMAT_JPEG,
                GmsDocumentScannerOptions.RESULT_FORMAT_PDF,
            )
            .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
            .build()

        GmsDocumentScanning.getClient(options)
            .getStartScanIntent(this)
            .addOnSuccessListener { intentSender ->
                startIntentSenderForResult(
                    intentSender,
                    scanRequestCode,
                    null,
                    0,
                    0,
                    0,
                    null,
                )
            }
            .addOnFailureListener { error ->
                finishPendingScanWithError(
                    "SCANNER_UNAVAILABLE",
                    error.localizedMessage ?: "ML Kit document scanner is unavailable.",
                )
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == scanRequestCode) {
            handleScanActivityResult(resultCode, data)
        }
    }

    private fun handleScanActivityResult(resultCode: Int, data: Intent?) {
        if (resultCode != Activity.RESULT_OK || data == null) {
            finishPendingScanWithError("CANCELLED", "Document scanning was cancelled.")
            return
        }

        val scanResult = GmsDocumentScanningResult.fromActivityResultIntent(data)
        val pages = scanResult?.pages.orEmpty()
        val pdfUri = scanResult?.pdf?.uri?.toString()

        executor.execute {
            try {
                val recognizedPages = pages.mapIndexed { index, page ->
                    recognizePage(index + 1, page.imageUri)
                }

                runOnUiThread {
                    pendingScanResult?.success(
                        mapOf(
                            "engine" to "ML Kit Document Scanner + Text Recognition v2",
                            "pdfUri" to pdfUri,
                            "pages" to recognizedPages,
                        ),
                    )
                    pendingScanResult = null
                }
            } catch (error: Exception) {
                runOnUiThread {
                    finishPendingScanWithError(
                        "OCR_FAILED",
                        error.localizedMessage ?: "Text recognition failed.",
                    )
                }
            }
        }
    }

    private fun recognizePage(pageNumber: Int, imageUri: Uri): Map<String, Any?> {
        val image = InputImage.fromFilePath(applicationContext, imageUri)
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        val result = try {
            Tasks.await(recognizer.process(image))
        } finally {
            recognizer.close()
        }
        val recognizedText = result.text
        val contentBlocks = result.textBlocks.map { block -> contentBlock(block) }
        val structuredText = contentBlocks
            .mapNotNull { block -> block["text"] as? String }
            .filter { text -> text.isNotBlank() }
            .joinToString("\n\n")
        val cleanedText = if (structuredText.isBlank()) {
            cleanRecognizedText(recognizedText)
        } else {
            structuredText
        }
        val confidence = if (cleanedText.isBlank()) 0.45 else 0.88

        return mapOf(
            "number" to pageNumber,
            "text" to cleanedText,
            "rawText" to recognizedText,
            "imageUri" to imageUri.toString(),
            "confidence" to confidence,
            "aiEngine" to "Local OCR cleanup; ready for Gemma LiteRT-LM",
            "lowConfidencePhrases" to lowConfidencePhrases(cleanedText),
            "contentBlocks" to contentBlocks,
        )
    }

    private fun contentBlock(block: Text.TextBlock): Map<String, Any?> {
        val lines = block.lines
        val type = when {
            isFigureCaption(block.text) -> "figure"
            isFormula(block.text) -> "formula"
            isTable(lines) -> "table"
            else -> "text"
        }
        val blockText = lines
            .joinToString("\n") { line ->
                if (type == "table") tableLine(line) else line.text.trim()
            }
            .trim()

        return mapOf(
            "type" to type,
            "text" to blockText,
            "confidence" to if (blockText.isBlank()) 0.45 else 0.88,
        )
    }

    private fun isFigureCaption(text: String): Boolean {
        return Regex(
            "^(fig(?:ure)?|diagram|chart|graph|illustration)\\s*[.:#-]?\\s*\\d*",
            RegexOption.IGNORE_CASE,
        ).containsMatchIn(text.trim())
    }

    private fun isFormula(text: String): Boolean {
        val compact = text.replace(" ", "")
        if (compact.isBlank()) return false

        val hasEquation = Regex("[A-Za-z0-9)²³ⁿ]+[=<>≈≤≥±×÷∑√∫][A-Za-z0-9(√∑∫]")
            .containsMatchIn(compact)
        val mathCharacters = compact.count { character ->
            character in "=+-×÷/<>≈≤≥±∑√∫^²³ⁿ()[]{}"
        }
        return hasEquation || (mathCharacters >= 2 && mathCharacters * 4 >= compact.length)
    }

    private fun isTable(lines: List<Text.Line>): Boolean {
        if (lines.size < 2) return false
        val gapCounts = lines.map { line ->
            val elements = line.elements.sortedBy { element -> element.boundingBox?.left ?: 0 }
            elements.zipWithNext().count { (left, right) ->
                val leftBox = left.boundingBox
                val rightBox = right.boundingBox
                leftBox != null && rightBox != null &&
                    rightBox.left - leftBox.right > maxOf(24, leftBox.height())
            }
        }
        return gapCounts.count { count -> count > 0 } >= 2 &&
            gapCounts.filter { count -> count > 0 }.distinct().size <= 2
    }

    private fun tableLine(line: Text.Line): String {
        val elements = line.elements.sortedBy { element -> element.boundingBox?.left ?: 0 }
        if (elements.isEmpty()) return line.text.trim()

        val result = StringBuilder(elements.first().text)
        elements.zipWithNext().forEach { (left, right) ->
            val leftBox = left.boundingBox
            val rightBox = right.boundingBox
            val isColumnGap = leftBox != null && rightBox != null &&
                rightBox.left - leftBox.right > maxOf(24, leftBox.height())
            result.append(if (isColumnGap) "\t" else " ")
            result.append(right.text)
        }
        return result.toString()
    }

    private fun cleanRecognizedText(text: String): String {
        if (text.isBlank()) return text.trim()

        val normalized = text
            .lines()
            .map { line -> line.trim().replace(Regex("\\s+"), " ") }
            .filter { line -> line.isNotBlank() }
            .joinToString("\n")

        return normalized
            .replace(" ,", ",")
            .replace(" .", ".")
            .replace(" ?", "?")
            .replace(" !", "!")
            .replace(Regex("(^|[.!?]\\s+)([a-z])")) { match ->
                match.groupValues[1] + match.groupValues[2].uppercase()
            }
    }

    private fun lowConfidencePhrases(text: String): List<String> {
        return text
            .lines()
            .filter { line -> line.length in 1..24 }
            .take(3)
    }

    private fun finishPendingScanWithError(code: String, message: String) {
        pendingScanResult?.error(code, message, null)
        pendingScanResult = null
    }
}
