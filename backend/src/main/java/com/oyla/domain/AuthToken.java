package com.oyla.domain;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity @Table(name = "auth_token")
public class AuthToken {
    @Id public UUID id;
    @Column(name = "user_id", nullable = false) public UUID userId;
    @Column(name = "session_id", nullable = false) public UUID sessionId;
    @Column(name = "token_hash", nullable = false, unique = true) public String tokenHash;
    @Column(nullable = false) public String kind;
    @Column(name = "expires_at", nullable = false) public Instant expiresAt;
    @Column(name = "revoked_at") public Instant revokedAt;
    @Column(name = "created_at", nullable = false) public Instant createdAt;
    protected AuthToken() {}
    public AuthToken(UUID userId, UUID sessionId, String hash, String kind, Instant now, Instant expiresAt) { this.id = UUID.randomUUID(); this.userId = userId; this.sessionId = sessionId; this.tokenHash = hash; this.kind = kind; this.createdAt = now; this.expiresAt = expiresAt; }
}
