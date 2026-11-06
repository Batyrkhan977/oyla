package com.oyla.api;

import com.oyla.service.YouTubeService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/v1/youtube")
public class YouTubeController {
    private final YouTubeService youtube;
    private final Map<String, long[]> requests = new HashMap<>();
    public YouTubeController(YouTubeService youtube) { this.youtube = youtube; }
    @GetMapping("/status") public Map<String, Boolean> status() { return Map.of("configured", youtube.configured()); }
    @GetMapping("/channels") public YouTubeService.ChannelPage channels(
        @RequestParam String kind, @RequestParam(defaultValue = "") String q,
        @RequestParam(defaultValue = "en") String language,
        @RequestParam(defaultValue = "") String pageToken, HttpServletRequest request) {
        limit(request);
        return youtube.channels(kind, q, language, pageToken);
    }
    @GetMapping("/videos") public YouTubeService.VideoPage videos(
        @RequestParam String channelId, @RequestParam int minimumMinutes,
        @RequestParam(defaultValue = "") String pageToken, HttpServletRequest request) {
        limit(request);
        return youtube.videos(channelId, minimumMinutes, pageToken);
    }
    private synchronized void limit(HttpServletRequest request) {
        long now = System.currentTimeMillis();
        requests.entrySet().removeIf(e -> now - e.getValue()[0] >= 60_000);
        String address = request.getRemoteAddr();
        if (!requests.containsKey(address) && requests.size() >= 1024) throw new YouTubeService.Unavailable("YOUTUBE_LIMITED");
        var window = requests.computeIfAbsent(address, ignored -> new long[]{now, 0});
        if (++window[1] > 60) throw new YouTubeService.Unavailable("YOUTUBE_LIMITED");
    }
    @ExceptionHandler(YouTubeService.Unavailable.class)
    ResponseEntity<Map<String, String>> unavailable(YouTubeService.Unavailable error) {
        return ResponseEntity.status(error.code.equals("YOUTUBE_LIMITED") ? 429 : 503)
            .body(Map.of("code", error.code));
    }
}
