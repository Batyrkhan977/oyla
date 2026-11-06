package com.oyla.app

import com.google.mlkit.common.model.DownloadConditions
import com.google.mlkit.common.model.RemoteModelManager
import com.google.mlkit.vision.digitalink.recognition.DigitalInkRecognition
import com.google.mlkit.vision.digitalink.recognition.DigitalInkRecognitionModel
import com.google.mlkit.vision.digitalink.recognition.DigitalInkRecognitionModelIdentifier
import com.google.mlkit.vision.digitalink.recognition.DigitalInkRecognizer
import com.google.mlkit.vision.digitalink.recognition.DigitalInkRecognizerOptions
import com.google.mlkit.vision.digitalink.recognition.Ink
import io.flutter.plugin.common.MethodChannel

object AndroidHandwritingRecognizer {
    private val exactNumber = Regex("^[0-9]+$")
    private val nonDigits = Regex("[^0-9]")

    fun recognize(rawStrokes: List<List<Map<String, Number>>>?, result: MethodChannel.Result) {
        if (rawStrokes.isNullOrEmpty()) {
            result.error("invalid_strokes", "No handwriting was provided.", null)
            return
        }

        val identifier = try {
            DigitalInkRecognitionModelIdentifier.fromLanguageTag("en-US")
        } catch (error: Exception) {
            result.error("model_error", error.localizedMessage, null)
            return
        }
        if (identifier == null) {
            result.error("model_error", "The English handwriting model is unavailable.", null)
            return
        }

        val ink = buildInk(rawStrokes)
        if (ink.strokes.isEmpty()) {
            result.error("invalid_strokes", "No valid handwriting points were provided.", null)
            return
        }
        val model = DigitalInkRecognitionModel.builder(identifier).build()
        val manager = RemoteModelManager.getInstance()
        manager.isModelDownloaded(model)
            .addOnSuccessListener { downloaded ->
                if (downloaded) {
                    runRecognition(model, ink, result)
                } else {
                    manager.download(model, DownloadConditions.Builder().build())
                        .addOnSuccessListener { runRecognition(model, ink, result) }
                        .addOnFailureListener { error ->
                            result.error(
                                "model_download_error",
                                "The handwriting model could not be downloaded. Check the connection and try again.",
                                error.localizedMessage)
                        }
                }
            }
            .addOnFailureListener { error ->
                result.error("model_error", error.localizedMessage, null)
            }
    }

    private fun buildInk(rawStrokes: List<List<Map<String, Number>>>): Ink {
        val ink = Ink.builder()
        var timestamp = 0L
        for (rawStroke in rawStrokes) {
            val stroke = Ink.Stroke.builder()
            var points = 0
            for (rawPoint in rawStroke) {
                val x = rawPoint["x"]?.toFloat() ?: continue
                val y = rawPoint["y"]?.toFloat() ?: continue
                stroke.addPoint(Ink.Point.create(x * 800f, y * 400f, timestamp++))
                points++
            }
            if (points > 0) ink.addStroke(stroke.build())
        }
        return ink.build()
    }

    private fun runRecognition(
        model: DigitalInkRecognitionModel,
        ink: Ink,
        result: MethodChannel.Result
    ) {
        val recognizer: DigitalInkRecognizer = DigitalInkRecognition.getClient(
            DigitalInkRecognizerOptions.builder(model).build())
        recognizer.recognize(ink)
            .addOnSuccessListener { recognition ->
                val texts = recognition.candidates.map { it.text.trim() }
                val answer = texts.firstOrNull { exactNumber.matches(it) }
                    ?: texts.map { it.replace(nonDigits, "") }.firstOrNull { it.isNotEmpty() }
                recognizer.close()
                result.success(answer)
            }
            .addOnFailureListener { error ->
                recognizer.close()
                result.error("recognition_error", error.localizedMessage, null)
            }
    }
}
