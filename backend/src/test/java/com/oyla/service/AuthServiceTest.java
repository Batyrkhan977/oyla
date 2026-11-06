package com.oyla.service;

import com.oyla.domain.AppUser;
import com.oyla.domain.AuthToken;
import com.oyla.domain.LoginCode;
import com.oyla.repository.AuthTokenRepository;
import com.oyla.repository.LoginCodeRepository;
import com.oyla.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {
    @Mock LoginCodeRepository codes;
    @Mock AuthTokenRepository tokens;
    @Mock UserRepository users;
    @Mock CodeDeliveryService delivery;

    @Test
    void backendCreatesAccountOnlyAfterVerifyingItsIssuedCode() {
        when(codes.findFirstByEmailOrderByCreatedAtDesc("person@example.com"))
                .thenReturn(Optional.empty());
        when(codes.save(any(LoginCode.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(users.findByEmail("person@example.com")).thenReturn(Optional.empty());
        when(users.save(any(AppUser.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(tokens.save(any(AuthToken.class))).thenAnswer(invocation -> invocation.getArgument(0));
        final var service = new AuthService(codes, tokens, users, delivery,
                "test-pepper", true, 10, 15, 30);

        final String issuedCode = service.requestCode(" Person@Example.com ").orElseThrow();
        final var storedCode = ArgumentCaptor.forClass(LoginCode.class);
        verify(codes).save(storedCode.capture());
        when(codes.findFirstByEmailOrderByCreatedAtDesc("person@example.com"))
                .thenReturn(Optional.of(storedCode.getValue()));

        final var session = service.verify("person@example.com", issuedCode);

        final var createdUser = ArgumentCaptor.forClass(AppUser.class);
        verify(users, atLeastOnce()).save(createdUser.capture());
        assertEquals("person@example.com", createdUser.getValue().email);
        assertNotNull(session.accessToken());
        assertNotNull(session.refreshToken());
        assertEquals(createdUser.getValue().id, session.userId());
        verify(tokens, times(2)).save(any(AuthToken.class));
        verifyNoInteractions(delivery);
    }

    @Test
    void invalidCodeDoesNotCreateAnAccountOrSession() {
        when(codes.findFirstByEmailOrderByCreatedAtDesc("person@example.com"))
                .thenReturn(Optional.empty());
        when(codes.save(any(LoginCode.class))).thenAnswer(invocation -> invocation.getArgument(0));
        final var service = new AuthService(codes, tokens, users, delivery,
                "test-pepper", true, 10, 15, 30);
        final String issuedCode = service.requestCode("person@example.com").orElseThrow();
        final var storedCode = ArgumentCaptor.forClass(LoginCode.class);
        verify(codes).save(storedCode.capture());
        when(codes.findFirstByEmailOrderByCreatedAtDesc("person@example.com"))
                .thenReturn(Optional.of(storedCode.getValue()));

        assertThrows(AuthService.InvalidCodeException.class,
                () -> service.verify("person@example.com",
                        issuedCode.equals("000000") ? "111111" : "000000"));
        verifyNoInteractions(users, tokens);
    }
}
