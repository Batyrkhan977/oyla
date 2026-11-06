package com.oyla.service;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.*;
import java.time.Duration;
import java.util.*;

/** Public YouTube metadata only. Credentials never leave the server. */
@Service
public class YouTubeService {
    public record Channel(String id, String title, String thumbnail) {}
    public record Video(String id, String title, String channelId, String channelTitle,
                        String thumbnail, long seconds) {}
    public record ChannelPage(List<Channel> items, String nextPageToken) {}
    public record VideoPage(List<Video> items, String nextPageToken) {}
    public static class Unavailable extends RuntimeException {
        public final String code;
        public Unavailable(String code) { super(code); this.code = code; }
    }
    private record Cached(JsonNode data, long expires) {}
    private final Map<String, Cached> cache = new LinkedHashMap<>();
    private final RestClient client;
    private final String key;
    private static final Map<String, String> TOPICS = Map.of(
        "exercise", "gentle low impact workout seniors", "walking", "indoor walking workout",
        "taiChi", "tai chi beginner follow along", "yoga", "gentle yoga beginners",
        "pilates", "beginner pilates", "custom", "gentle movement exercise",
        "cognitive", "brain exercise memory", "reading", "reading books");

    @org.springframework.beans.factory.annotation.Autowired
    public YouTubeService(@Value("${oyla.youtube.api-key:}") String key) {
        this(key, httpClient());
    }
    // Injectable transport for tests; production always calls Google's fixed host.
    YouTubeService(String key, RestClient client) { this.key = key; this.client = client; }
    private static RestClient httpClient() {
        var factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(5000); factory.setReadTimeout(10000);
        return RestClient.builder().baseUrl("https://www.googleapis.com/youtube/v3")
            .requestFactory(factory).build();
    }
    public boolean configured() { return !key.isBlank(); }
    public ChannelPage channels(String kind, String query, String language, String page) {
        if (!TOPICS.containsKey(kind) || !Set.of("en", "kk", "ru").contains(language)
            || query.length() > 100) throw new IllegalArgumentException();
        validatePage(page);
        var params = new LinkedHashMap<String, String>();
        params.put("part", "snippet"); params.put("type", "channel");
        params.put("q", query.isBlank() ? TOPICS.get(kind) : query.trim());
        params.put("safeSearch", "strict"); params.put("relevanceLanguage", language);
        params.put("maxResults", query.isBlank() ? "3" : "10");
        if (!page.isBlank()) params.put("pageToken", page);
        var data = get("search", params);
        var result = new ArrayList<Channel>();
        for (var item : data.path("items")) {
            String id = item.path("id").path("channelId").asText();
            if (!validChannel(id)) continue;
            var snippet = item.path("snippet");
            result.add(new Channel(id, snippet.path("title").asText(), thumbnail(snippet)));
        }
        return new ChannelPage(result, token(data));
    }
    public VideoPage videos(String channelId, int minimumMinutes, String page) {
        if (!validChannel(channelId) || minimumMinutes < 1 || minimumMinutes > 240)
            throw new IllegalArgumentException();
        validatePage(page);
        var channel = get("channels", Map.of("part", "contentDetails", "id", channelId));
        var uploads = channel.path("items").path(0).path("contentDetails")
            .path("relatedPlaylists").path("uploads").asText();
        if (uploads.isBlank()) return new VideoPage(List.of(), null);
        var params = new LinkedHashMap<String, String>();
        params.put("part", "contentDetails"); params.put("playlistId", uploads);
        params.put("maxResults", "50");
        if (!page.isBlank()) params.put("pageToken", page);
        var data = get("playlistItems", params);
        var ids = new ArrayList<String>();
        for (var item : data.path("items")) {
            String id = item.path("contentDetails").path("videoId").asText();
            if (id.matches("[A-Za-z0-9_-]{11}")) ids.add(id);
        }
        if (ids.isEmpty()) return new VideoPage(List.of(), token(data));
        var details = get("videos", Map.of("part", "snippet,contentDetails,status", "id", String.join(",", ids)));
        var videos = new ArrayList<Video>();
        for (var item : details.path("items")) {
            var snippet = item.path("snippet"); var status = item.path("status");
            long seconds;
            try { seconds = Duration.parse(item.path("contentDetails").path("duration").asText()).getSeconds(); }
            catch (RuntimeException ignored) { continue; }
            // Deleted/private, live/upcoming, and unprocessed videos never become exercises.
            if (seconds < minimumMinutes * 60L || !channelId.equals(snippet.path("channelId").asText())
                || !"public".equals(status.path("privacyStatus").asText())
                || !"processed".equals(status.path("uploadStatus").asText())
                || !"none".equals(snippet.path("liveBroadcastContent").asText())) continue;
            videos.add(new Video(item.path("id").asText(), snippet.path("title").asText(), channelId,
                snippet.path("channelTitle").asText(), thumbnail(snippet), seconds));
        }
        return new VideoPage(videos, token(data));
    }
    private static boolean validChannel(String id) { return id.matches("UC[A-Za-z0-9_-]{22}"); }
    private static void validatePage(String page) {
        if (page.length() > 512 || (!page.isBlank() && !page.matches("[A-Za-z0-9_=-]+")))
            throw new IllegalArgumentException();
    }
    private static String token(JsonNode data) { return data.hasNonNull("nextPageToken") ? data.path("nextPageToken").asText() : null; }
    private static String thumbnail(JsonNode snippet) {
        var url = snippet.path("thumbnails").path("medium").path("url").asText();
        return url.startsWith("https://") ? url : "";
    }
    // Short-lived, bounded metadata cache also avoids repeated search quota charges.
    private synchronized JsonNode get(String path, Map<String, String> params) {
        if (!configured()) throw new Unavailable("YOUTUBE_NOT_CONFIGURED");
        String cacheKey = path + new TreeMap<>(params);
        long now = System.currentTimeMillis();
        var cached = cache.get(cacheKey);
        if (cached != null && cached.expires > now) return cached.data;
        try {
            JsonNode data = client.get().uri(builder -> {
                builder.path("/" + path);
                params.forEach(builder::queryParam);
                return builder.queryParam("key", key).build();
            }).retrieve().body(JsonNode.class);
            if (data == null) throw new Unavailable("YOUTUBE_UNAVAILABLE");
            cache.entrySet().removeIf(e -> e.getValue().expires <= now);
            if (cache.size() >= 256) cache.remove(cache.keySet().iterator().next());
            cache.put(cacheKey, new Cached(data, now + 5 * 60_000));
            return data;
        } catch (RestClientResponseException e) {
            // Do not forward Google's body or request URI, which can contain the key.
            throw new Unavailable(e.getStatusCode().value() == 403 || e.getStatusCode().value() == 429
                ? "YOUTUBE_LIMITED" : "YOUTUBE_UNAVAILABLE");
        } catch (RestClientException e) { throw new Unavailable("YOUTUBE_UNAVAILABLE"); }
    }
}
