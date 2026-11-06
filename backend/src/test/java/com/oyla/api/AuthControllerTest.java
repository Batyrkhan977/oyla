package com.oyla.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oyla.service.AuthService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.context.annotation.Import;
import com.oyla.security.*;
import java.util.Optional;
import java.util.UUID;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(AuthController.class)
@Import({SecurityConfig.class, BearerAuthenticationFilter.class, ApiExceptionHandler.class})
class AuthControllerTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @MockBean AuthService auth;
    @Test void requestCodeDoesNotRequireAuthentication() throws Exception {
        when(auth.requestCode("person@example.com")).thenReturn(Optional.empty());
        mvc.perform(post("/api/v1/auth/code/request").contentType(MediaType.APPLICATION_JSON).content("{\"email\":\"person@example.com\"}"))
                .andExpect(status().isAccepted()).andExpect(jsonPath("$.message").exists());
    }
    @Test void rejectsMalformedEmail() throws Exception {
        mvc.perform(post("/api/v1/auth/code/request").contentType(MediaType.APPLICATION_JSON).content("{\"email\":\"wrong\"}"))
                .andExpect(status().isBadRequest());
    }
    @Test void verifiesCodeAndReturnsAnAccountSession() throws Exception {
        final var userId = UUID.randomUUID();
        when(auth.verify("person@example.com", "123456"))
                .thenReturn(new AuthService.TokenPair("access", "refresh", 900, userId));
        mvc.perform(post("/api/v1/auth/code/verify")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"person@example.com\",\"code\":\"123456\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").value("access"))
                .andExpect(jsonPath("$.refreshToken").value("refresh"))
                .andExpect(jsonPath("$.userId").value(userId.toString()));
    }
    @Test void rejectsMalformedVerificationCode() throws Exception {
        mvc.perform(post("/api/v1/auth/code/verify")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"person@example.com\",\"code\":\"123\"}"))
                .andExpect(status().isBadRequest());
        verify(auth, never()).verify(anyString(), anyString());
    }
}
