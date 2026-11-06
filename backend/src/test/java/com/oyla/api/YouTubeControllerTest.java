package com.oyla.api;

import com.oyla.service.*;
import com.oyla.security.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;
import java.util.List;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(YouTubeController.class)
@Import({SecurityConfig.class, BearerAuthenticationFilter.class, ApiExceptionHandler.class})
class YouTubeControllerTest {
    @Autowired MockMvc mvc;
    @MockBean YouTubeService youtube;
    @MockBean AuthService auth;
    @Test void publicSearchWorksForGuestAndAcceptsDuration() throws Exception {
        when(youtube.channels("yoga", "", "en", "")).thenReturn(new YouTubeService.ChannelPage(List.of(), null));
        mvc.perform(get("/api/v1/youtube/channels").param("kind", "yoga"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.items").isArray());
        when(youtube.videos("channel", 15, "")).thenReturn(new YouTubeService.VideoPage(List.of(), "older"));
        mvc.perform(get("/api/v1/youtube/videos").param("channelId", "channel").param("minimumMinutes", "15"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.nextPageToken").value("older"));
    }
    @Test void missingKeyIsAnExplicitServiceErrorNotLoginFailure() throws Exception {
        when(youtube.channels("yoga", "", "en", "")).thenThrow(new YouTubeService.Unavailable("YOUTUBE_NOT_CONFIGURED"));
        mvc.perform(get("/api/v1/youtube/channels").param("kind", "yoga"))
            .andExpect(status().isServiceUnavailable()).andExpect(jsonPath("$.code").value("YOUTUBE_NOT_CONFIGURED"));
        mvc.perform(get("/api/v1/youtube/status"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.configured").value(false));
    }
}
