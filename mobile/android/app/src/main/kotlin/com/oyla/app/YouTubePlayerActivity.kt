package com.oyla.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.activity.OnBackPressedCallback
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.PlayerConstants
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.YouTubePlayer
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.listeners.AbstractYouTubePlayerListener
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.listeners.FullscreenListener
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.options.IFramePlayerOptions
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.views.YouTubePlayerView

/** A lifecycle-owned WebView player. Exercise completion stays explicit in Flutter. */
class YouTubePlayerActivity : ComponentActivity() {
    private var position = 0f
    private var exitFullscreen: (() -> Unit)? = null
    private var language = "en"
    private var activeVideoId = ""

    private fun words(en: String, kk: String, ru: String) = when (language) {
        "kk" -> kk
        "ru" -> ru
        else -> en
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val requestedId = intent.getStringExtra("videoId") ?: ""
        val recordings = (listOf(requestedId) +
            (intent.getStringArrayListExtra("alternativeVideoIds") ?: emptyList()))
            .filter { Regex("^[a-zA-Z0-9_-]{11}$").matches(it) }.distinct()
        var videoId = savedInstanceState?.getString("videoId")
            ?.takeIf { it in recordings } ?: requestedId
        val songTitle = intent.getStringExtra("songTitle")?.takeIf { it.isNotBlank() }
        if (!Regex("^[a-zA-Z0-9_-]{11}$").matches(videoId)) {
            finish()
            return
        }
        activeVideoId = videoId
        language = intent.getStringExtra("language") ?: "en"
        position = savedInstanceState?.getFloat("position") ?: 0f
        val root = FrameLayout(this).apply { fitsSystemWindows = true }
        val content = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        val fullscreen = FrameLayout(this).apply {
            visibility = View.GONE
            setBackgroundColor(android.graphics.Color.BLACK)
        }
        root.addView(content, FrameLayout.LayoutParams(-1, -1))
        root.addView(fullscreen, FrameLayout.LayoutParams(-1, -1))
        setContentView(root)
        content.addView(Button(this).apply {
            text = words("Back to activity", "Әрекетке оралу", "Вернуться к занятию")
            setOnClickListener { finish() }
        })
        val playerView = YouTubePlayerView(this).apply {
            enableAutomaticInitialization = false
        }
        content.addView(playerView, LinearLayout.LayoutParams(-1, 0, 1f))
        val status = TextView(this).apply {
            text = words("Loading video…", "Видео жүктелуде…", "Загрузка видео…")
            setPadding(24, 16, 24, 16)
            accessibilityLiveRegion = View.ACCESSIBILITY_LIVE_REGION_POLITE
        }
        content.addView(status)
        var player: YouTubePlayer? = null
        val alternative = Button(this).apply {
            text = words("Try another recording", "Басқа жазбаны тыңдау", "Попробовать другую запись")
            visibility = View.GONE
            setOnClickListener {
                val next = recordings.getOrNull(recordings.indexOf(videoId) + 1)
                if (next != null) {
                    videoId = next
                    activeVideoId = next
                    position = 0f
                    status.text = words("Loading video…", "Видео жүктелуде…", "Загрузка видео…")
                    visibility = View.GONE
                    player?.cueVideo(next, 0f)
                }
            }
        }
        content.addView(alternative)
        content.addView(Button(this).apply {
            text = words("Retry", "Қайталау", "Повторить")
            setOnClickListener { recreate() }
        })
        content.addView(Button(this).apply {
            text = words("Open in YouTube", "YouTube-та ашу", "Открыть в YouTube")
            setOnClickListener {
                try {
                    startActivity(Intent(Intent.ACTION_VIEW,
                        Uri.parse("https://www.youtube.com/watch?v=$videoId")))
                } catch (_: android.content.ActivityNotFoundException) {
                    status.text = words("No browser available. Return to use the timer.",
                        "Браузер жоқ. Таймерге оралыңыз.", "Браузер недоступен. Вернитесь к таймеру.")
                }
            }
        })
        if (songTitle != null) {
            content.addView(Button(this).apply {
                text = words("Find another recording", "Басқа жазбаны іздеу", "Найти другую запись")
                setOnClickListener {
                    val search = Uri.parse("https://www.youtube.com/results").buildUpon()
                        .appendQueryParameter("search_query", songTitle).build()
                    try {
                        startActivity(Intent(Intent.ACTION_VIEW, search))
                    } catch (_: android.content.ActivityNotFoundException) {
                        status.text = words("No browser is available.", "Браузер қолжетімсіз.", "Браузер недоступен.")
                    }
                }
            })
        }
        lifecycle.addObserver(playerView)
        playerView.addFullscreenListener(object : FullscreenListener {
            override fun onEnterFullscreen(fullscreenView: View, exitFullscreen: () -> Unit) {
                this@YouTubePlayerActivity.exitFullscreen = exitFullscreen
                content.visibility = View.GONE
                fullscreen.visibility = View.VISIBLE
                fullscreen.addView(fullscreenView, ViewGroup.LayoutParams(-1, -1))
            }
            override fun onExitFullscreen() {
                exitFullscreen = null
                fullscreen.removeAllViews()
                fullscreen.visibility = View.GONE
                content.visibility = View.VISIBLE
            }
        })
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                val exit = exitFullscreen
                if (exit != null) exit() else finish()
            }
        })
        playerView.initialize(object : AbstractYouTubePlayerListener() {
            override fun onReady(youTubePlayer: YouTubePlayer) {
                player = youTubePlayer
                status.text = ""
                // Cue rather than autoplay so a delayed network response cannot
                // start audio after the user has left this screen.
                youTubePlayer.cueVideo(videoId, position)
            }
            override fun onStateChange(youTubePlayer: YouTubePlayer, state: PlayerConstants.PlayerState) {
                if (state == PlayerConstants.PlayerState.PLAYING || state == PlayerConstants.PlayerState.VIDEO_CUED) {
                    status.text = ""
                    alternative.visibility = View.GONE
                }
            }
            override fun onCurrentSecond(youTubePlayer: YouTubePlayer, second: Float) {
                position = second
            }
            override fun onError(youTubePlayer: YouTubePlayer, error: PlayerConstants.PlayerError) {
                exitFullscreen?.invoke()
                Log.w("OylaYouTube", "Playback failed for $videoId: $error")
                alternative.visibility = if (recordings.indexOf(videoId) < recordings.lastIndex) View.VISIBLE else View.GONE
                status.text = when (error) {
                    PlayerConstants.PlayerError.VIDEO_NOT_FOUND -> words(
                        "This recording was removed or made private. Choose another recording.",
                        "Бұл жазба жойылған немесе жабық. Басқа жазбаны таңдаңыз.",
                        "Эта запись удалена или закрыта. Выберите другую запись.")
                    PlayerConstants.PlayerError.VIDEO_NOT_PLAYABLE_IN_EMBEDDED_PLAYER -> words(
                        "This recording cannot play inside the app. Open it in YouTube or choose another recording.",
                        "Бұл жазба қолданба ішінде ойнатылмайды. YouTube-та ашыңыз немесе басқа жазбаны таңдаңыз.",
                        "Эту запись нельзя воспроизвести в приложении. Откройте её в YouTube или выберите другую запись.")
                    PlayerConstants.PlayerError.REQUEST_MISSING_HTTP_REFERER -> words(
                        "YouTube could not verify this player. Open the recording in YouTube.",
                        "YouTube бұл ойнатқышты растай алмады. Жазбаны YouTube-та ашыңыз.",
                        "YouTube не смог проверить плеер. Откройте запись в YouTube.")
                    else -> words(
                        "Playback failed. Check your connection, retry, or open in YouTube.",
                        "Ойнату сәтсіз аяқталды. Байланысты тексеріп, қайталаңыз немесе YouTube-та ашыңыз.",
                        "Не удалось воспроизвести запись. Проверьте соединение, повторите или откройте в YouTube.")
                }
            }
        }, IFramePlayerOptions.Builder(this).controls(1).fullscreen(1).langPref(language).build())
    }

    override fun onSaveInstanceState(outState: Bundle) {
        outState.putFloat("position", position)
        outState.putString("videoId", activeVideoId)
        super.onSaveInstanceState(outState)
    }
}
