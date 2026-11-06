package com.oyla.service;

import org.junit.jupiter.api.*;
import org.springframework.http.*;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.*;

class YouTubeServiceTest {
    static final String CHANNEL = "UCabcdefghijklmnopqrstuv";
    MockRestServiceServer server;
    YouTubeService youtube;
    @BeforeEach void setup() {
        var builder = RestClient.builder().baseUrl("https://www.googleapis.com/youtube/v3");
        server = MockRestServiceServer.bindTo(builder).build();
        youtube = new YouTubeService("test-only", builder.build());
    }
    void reply(String path, String body) {
        server.expect(requestTo(org.hamcrest.Matchers.containsString("/" + path + "?")))
            .andRespond(withSuccess(body, MediaType.APPLICATION_JSON));
    }
    @Test void recommendationsUseActivityTopicThreeResultsAndCache() {
        server.expect(queryParam("q", "gentle%20yoga%20beginners"))
            .andExpect(queryParam("type", "channel")).andExpect(queryParam("maxResults", "3"))
            .andRespond(withSuccess("{\"items\":[{\"id\":{\"channelId\":\"" + CHANNEL + "\"},\"snippet\":{\"title\":\"Gentle Yoga\"}}]}", MediaType.APPLICATION_JSON));
        assertEquals("Gentle Yoga", youtube.channels("yoga", "", "en", "").items().getFirst().title());
        youtube.channels("yoga", "", "en", "");
        server.verify();
    }
    @Test void searchPreservesQueryLanguageAndPagination() {
        server.expect(queryParam("q", "Yoga%20%26%20movement"))
            .andExpect(queryParam("relevanceLanguage", "ru")).andExpect(queryParam("pageToken", "page2"))
            .andRespond(withSuccess("{\"items\":[],\"nextPageToken\":\"page3\"}", MediaType.APPLICATION_JSON));
        assertEquals("page3", youtube.channels("yoga", "Yoga & movement", "ru", "page2").nextPageToken());
        server.verify();
    }
    String video(String id, String duration, String privacy, String live, String channel) {
        return "{\"id\":\""+id+"\",\"snippet\":{\"title\":\"Session\",\"channelId\":\""+channel+"\",\"channelTitle\":\"Yoga\",\"liveBroadcastContent\":\""+live+"\"},\"contentDetails\":{\"duration\":\""+duration+"\"},\"status\":{\"privacyStatus\":\""+privacy+"\",\"uploadStatus\":\"processed\"}}";
    }
    @Test void exactDurationThresholdExcludesShortPrivateLiveAndWrongChannel() {
        reply("channels", "{\"items\":[{\"contentDetails\":{\"relatedPlaylists\":{\"uploads\":\"uploads\"}}}]}");
        reply("playlistItems", "{\"items\":[{\"contentDetails\":{\"videoId\":\"abcdefghijk\"}}],\"nextPageToken\":\"older\"}");
        reply("videos", "{\"items\":[" +
            video("short", "PT14M59S", "public", "none", CHANNEL)+","+
            video("exact", "PT15M", "public", "none", CHANNEL)+","+
            video("long", "PT1H2M", "public", "none", CHANNEL)+","+
            video("private", "PT20M", "private", "none", CHANNEL)+","+
            video("live", "PT20M", "public", "live", CHANNEL)+","+
            video("wrong", "PT20M", "public", "none", "other")+"]}");
        var page = youtube.videos(CHANNEL, 15, "");
        assertEquals(2, page.items().size());
        assertEquals(900, page.items().getFirst().seconds());
        assertEquals(3720, page.items().getLast().seconds());
        assertEquals("older", page.nextPageToken());
        server.verify();
    }
    @Test void emptyPageRetainsCursorRatherThanClaimingNoVideoExists() {
        reply("channels", "{\"items\":[{\"contentDetails\":{\"relatedPlaylists\":{\"uploads\":\"uploads\"}}}]}");
        reply("playlistItems", "{\"items\":[],\"nextPageToken\":\"older\"}");
        var page = youtube.videos(CHANNEL, 240, "");
        assertTrue(page.items().isEmpty()); assertEquals("older", page.nextPageToken());
        server.verify();
    }
    @Test void absentKeyAndUpstreamErrorsHaveSafeExplicitCodes() {
        assertEquals("YOUTUBE_NOT_CONFIGURED", assertThrows(YouTubeService.Unavailable.class,
            () -> new YouTubeService("").channels("yoga", "", "en", "")).code);
        server.expect(queryParam("key", "test-only"))
            .andRespond(withStatus(HttpStatus.FORBIDDEN).body("secret upstream details"));
        var error = assertThrows(YouTubeService.Unavailable.class, () -> youtube.channels("yoga", "", "en", ""));
        assertEquals("YOUTUBE_LIMITED", error.code); assertFalse(error.getMessage().contains("secret"));
    }
    @Test void validatesCallerParametersBeforeCallingGoogle() {
        assertThrows(IllegalArgumentException.class, () -> youtube.channels("unknown", "", "en", ""));
        assertThrows(IllegalArgumentException.class, () -> youtube.videos("https://example.com", 15, ""));
        assertThrows(IllegalArgumentException.class, () -> youtube.videos(CHANNEL, 0, ""));
        server.verify();
    }
}
