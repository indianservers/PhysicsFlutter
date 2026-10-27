package com.indianservers.physics_atelier

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.Handler
import android.os.Looper

class MainActivity : FlutterActivity() {
    private var tone: AudioTrack? = null
    private val handler = Handler(Looper.getMainLooper())
    private val releaseTone = Runnable { stopTone() }
    private fun stopTone() {
        handler.removeCallbacks(releaseTone)
        val active = tone
        tone = null
        if (active != null) {
            try { active.stop() } catch (_: IllegalStateException) { }
            active.release()
        }
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "physics_atelier/generated_audio")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "stop" -> { stopTone(); result.success(null) }
                    "play" -> {
                        stopTone()
                        val pcm = call.argument<ByteArray>("pcm")
                        val rate = call.argument<Int>("rate")
                        val volume = call.argument<Double>("volume")
                        if (pcm == null || pcm.isEmpty() || pcm.size % 2 != 0 ||
                            pcm.size > 65536 || rate != 16384 || volume == null || !volume.isFinite()) {
                            result.error("invalid_audio", "Unsupported generated preview", null)
                        } else {
                            try {
                                val track = AudioTrack.Builder()
                                    .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
                                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build())
                                    .setAudioFormat(AudioFormat.Builder().setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                                        .setSampleRate(rate).setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
                                    .setBufferSizeInBytes(pcm.size).setTransferMode(AudioTrack.MODE_STATIC).build()
                                tone = track
                                check(track.write(pcm, 0, pcm.size) == pcm.size)
                                track.setVolume(volume.coerceIn(0.0, 0.2).toFloat())
                                track.play()
                                handler.postDelayed(releaseTone, 2100)
                                result.success(null)
                            } catch (_: Exception) {
                                stopTone()
                                result.error("audio_unavailable", "Device cannot play this preview", null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
    override fun onPause() { stopTone(); super.onPause() }
    override fun onDestroy() { stopTone(); super.onDestroy() }
}
