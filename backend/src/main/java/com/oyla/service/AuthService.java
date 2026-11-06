package com.oyla.service;

import com.oyla.domain.*;
import com.oyla.repository.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.*;
import java.time.*;
import java.util.*;

@Service
public class AuthService {
    private static final Logger log = LoggerFactory.getLogger(AuthService.class);
    private final LoginCodeRepository codes;
    private final AuthTokenRepository tokens;
    private final UserRepository users;
    private final CodeDeliveryService delivery;
    private final SecureRandom random = new SecureRandom();
    private final String pepper;
    private final boolean exposeCode;
    private final long codeMinutes, accessMinutes, refreshDays;

    public AuthService(LoginCodeRepository codes, AuthTokenRepository tokens, UserRepository users, CodeDeliveryService delivery,
                       @Value("${oyla.auth.pepper}") String pepper,
                       @Value("${oyla.auth.expose-code:false}") boolean exposeCode,
                       @Value("${oyla.auth.code-minutes:10}") long codeMinutes,
                       @Value("${oyla.auth.access-minutes:15}") long accessMinutes,
                       @Value("${oyla.auth.refresh-days:30}") long refreshDays) {
        this.codes = codes; this.tokens = tokens; this.users = users; this.delivery = delivery; this.pepper = pepper; this.exposeCode = exposeCode;
        this.codeMinutes = codeMinutes; this.accessMinutes = accessMinutes; this.refreshDays = refreshDays;
    }

    @Transactional
    public Optional<String> requestCode(String rawEmail) {
        final String email = normalizeEmail(rawEmail);
        final Instant now = Instant.now();
        codes.findFirstByEmailOrderByCreatedAtDesc(email).ifPresent(previous -> {
            if (previous.createdAt.isAfter(now.minusSeconds(60))) throw new TooManyRequestsException();
        });
        final String code = String.format("%06d", random.nextInt(1_000_000));
        codes.save(new LoginCode(email, hash(code), now, now.plus(Duration.ofMinutes(codeMinutes))));
        if (exposeCode) log.warn("DEVELOPMENT ONLY sign-in code for {} is {}", maskEmail(email), code);
        else delivery.send(email, code);
        return exposeCode ? Optional.of(code) : Optional.empty();
    }

    @Transactional
    public TokenPair verify(String rawEmail, String code) {
        final String email = normalizeEmail(rawEmail);
        final Instant now = Instant.now();
        final LoginCode record = codes.findFirstByEmailOrderByCreatedAtDesc(email).orElseThrow(InvalidCodeException::new);
        if (record.consumedAt != null || !record.expiresAt.isAfter(now) || record.attempts >= 5) throw new InvalidCodeException();
        record.attempts++;
        if (!MessageDigest.isEqual(record.codeHash.getBytes(StandardCharsets.UTF_8), hash(code).getBytes(StandardCharsets.UTF_8))) {
            codes.save(record); throw new InvalidCodeException();
        }
        record.consumedAt = now; codes.save(record);
        final AppUser user = users.findByEmail(email).orElseGet(() -> users.save(new AppUser(email, now)));
        user.lastSignInAt = now; users.save(user);
        return issuePair(user.id, UUID.randomUUID(), now);
    }

    @Transactional
    public TokenPair refresh(String rawRefreshToken) {
        final Instant now = Instant.now();
        final AuthToken old = tokens.findByTokenHash(hash(rawRefreshToken)).orElseThrow(InvalidTokenException::new);
        if (!old.kind.equals("REFRESH") || old.revokedAt != null || !old.expiresAt.isAfter(now)) throw new InvalidTokenException();
        old.revokedAt = now; tokens.save(old);
        return issuePair(old.userId, old.sessionId, now);
    }

    @Transactional
    public void revoke(String rawToken) {
        tokens.findByTokenHash(hash(rawToken)).ifPresent(token -> {
            final Instant now = Instant.now();
            final var session = tokens.findBySessionId(token.sessionId);
            session.forEach(item -> item.revokedAt = now);
            tokens.saveAll(session);
        });
    }

    public Optional<UUID> authenticate(String rawAccessToken) {
        final Instant now = Instant.now();
        return tokens.findByTokenHash(hash(rawAccessToken))
                .filter(t -> t.kind.equals("ACCESS") && t.revokedAt == null && t.expiresAt.isAfter(now)).map(t -> t.userId);
    }

    private TokenPair issuePair(UUID userId, UUID sessionId, Instant now) {
        final String access = randomToken(), refresh = randomToken();
        tokens.save(new AuthToken(userId, sessionId, hash(access), "ACCESS", now, now.plus(Duration.ofMinutes(accessMinutes))));
        tokens.save(new AuthToken(userId, sessionId, hash(refresh), "REFRESH", now, now.plus(Duration.ofDays(refreshDays))));
        return new TokenPair(access, refresh, accessMinutes * 60, userId);
    }

    private String randomToken() { final byte[] value = new byte[32]; random.nextBytes(value); return Base64.getUrlEncoder().withoutPadding().encodeToString(value); }
    private String hash(String value) {
        try { return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest((pepper + value).getBytes(StandardCharsets.UTF_8))); }
        catch (NoSuchAlgorithmException impossible) { throw new IllegalStateException(impossible); }
    }
    private static String normalizeEmail(String email) { return email.strip().toLowerCase(Locale.ROOT); }
    private static String maskEmail(String email) { final int at = email.indexOf('@'); return at <= 1 ? "***" + email.substring(Math.max(0, at)) : email.substring(0, 1) + "***" + email.substring(at); }

    public record TokenPair(String accessToken, String refreshToken, long expiresInSeconds, UUID userId) {}
    public static class InvalidCodeException extends RuntimeException {}
    public static class InvalidTokenException extends RuntimeException {}
    public static class TooManyRequestsException extends RuntimeException {}
}
