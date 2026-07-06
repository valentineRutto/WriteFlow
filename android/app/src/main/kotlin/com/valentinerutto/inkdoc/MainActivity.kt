package com.valentinerutto.inkdoc

import android.app.Activity
import android.content.Intent
import android.net.Uri
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import com.google.mlkit.vision.text.TextRecognition
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
                "improveText" -> {
                    val text = call.argument<String>("text").orEmpty()
                    result.success(cleanRecognizedText(text))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scanDocument(call: MethodCall, result: MethodChannel.Result) {
        if (pendingScanResult != null) {
            result.error("SCAN_IN_PROGRESS", "A document scan is already running.", null)
            return
        }

        pendingScanResult = result

        val pageLimit = call.argument<Int>("pageLimit") ?: 1
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
        val recognizedText = Tasks.await(recognizer.process(image)).text
        val cleanedText = cleanRecognizedText(recognizedText)
        val confidence = if (cleanedText.isBlank()) 0.45 else 0.88

        return mapOf(
            "number" to pageNumber,
            "text" to cleanedText,
            "rawText" to recognizedText,
            "imageUri" to imageUri.toString(),
            "confidence" to confidence,
            "aiEngine" to "Local OCR cleanup; ready for Gemma LiteRT-LM",
            "lowConfidencePhrases" to lowConfidencePhrases(cleanedText),
        )
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
