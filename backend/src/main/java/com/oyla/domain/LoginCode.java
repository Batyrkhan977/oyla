package com.oyla.domain;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity @Table(name = "login_code")
public class LoginCode {
    @Id public UUID id;
    @Column(nullable = false) public String email;
    @Column(name = "code_hash", nullable = false) public String codeHash;
    @Column(name = "expires_at", nullable = false) public Instant expiresAt;
    @Column(nullable = false) public int attempts;
    @Column(name = "consumed_at") public Instant consumedAt;
    @Column(name = "created_at", nullable = false) public Instant createdAt;
    protected LoginCode() {}
    public LoginCode(String email, String hash, Instant now, Instant expiresAt) { this.id = UUID.randomUUID(); this.email = email; this.codeHash = hash; this.createdAt = now; this.expiresAt = expiresAt; }
}
