package com.oyla.app

import android.app.Activity
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.speech.RecognizerIntent
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import kotlin.math.*

/** Synthesized, original tones; no recorded audio or microphone files. */
class MusicVoiceBridge(private val activity: Activity, channel: MethodChannel) {
    private val executor = Executors.newSingleThreadExecutor()
    private var speechResult: MethodChannel.Result? = null
    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "note" -> {
                    val midi = (call.argument<Int>("midi") ?: 60).coerceIn(48, 84)
                    val ms = (call.argument<Int>("ms") ?: 350).coerceIn(80, 1500)
                    executor.execute {
                        val rate = 22050
                        val count = rate * ms / 1000
                        val frequency = 440.0 * 2.0.pow((midi - 69) / 12.0)
                        val samples = ShortArray(count) { i ->
                            val envelope = min(1.0, i / 200.0) * min(1.0, (count-i) / 600.0)
                            (sin(2 * PI * frequency * i / rate) * 10000 * envelope).toInt().toShort()
                        }
                        var track: AudioTrack? = null
                        try {
                            track = AudioTrack.Builder()
                                .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build())
                                .setAudioFormat(AudioFormat.Builder().setSampleRate(rate).setEncoding(AudioFormat.ENCODING_PCM_16BIT).setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
                                .setBufferSizeInBytes(count * 2).setTransferMode(AudioTrack.MODE_STATIC).build()
                            track.write(samples, 0, samples.size)
                            track.play()
                            Thread.sleep(ms.toLong())
                            activity.runOnUiThread { result.success(null) }
                        } catch (_: Exception) {
                            activity.runOnUiThread { result.error("AUDIO", "Sound is unavailable", null) }
                        } finally { track?.release() }
                    }
                }
                "recognize" -> {
                    if (speechResult != null) result.error("BUSY", "Recognition is already active", null)
                    else try {
                        speechResult = result
                        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
                            .putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                            .putExtra(RecognizerIntent.EXTRA_LANGUAGE, call.argument<String>("language") ?: "en-US")
                            .putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
                        activity.startActivityForResult(intent, 706)
                    } catch (_: Exception) {
                        speechResult = null
                        result.error("UNAVAILABLE", "Speech recognition is not installed", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    fun result(request: Int, code: Int, data: Intent?): Boolean {
        if (request != 706) return false
        speechResult?.success(if (code == Activity.RESULT_OK) data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)?.firstOrNull() else null)
        speechResult = null
        return true
    }
    fun close() { speechResult?.success(null); speechResult = null; executor.shutdown() }
}
