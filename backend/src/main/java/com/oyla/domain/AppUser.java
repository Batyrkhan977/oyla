package com.oyla.domain;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity @Table(name = "app_user")
public class AppUser {
    @Id public UUID id;
    @Column(nullable = false, unique = true) public String email;
    public String nickname;
    // Production PostgreSQL enforces NOT NULL through Flyway. Local H2 keeps
    // this nullable during schema update so existing accounts can be backfilled.
    @Column(name = "friend_code", unique = true, length = 10) public String friendCode;
    @Column(nullable = false) public String status;
    @Column(nullable = false) public String locale;
    @Column(nullable = false) public String timezone;
    @Column(name = "settings_json", nullable = false, columnDefinition = "text") public String settingsJson;
    @Column(name = "settings_updated_at", nullable = false) public Instant settingsUpdatedAt;
    @Column(name = "created_at", nullable = false) public Instant createdAt;
    @Column(name = "last_sign_in_at") public Instant lastSignInAt;
    protected AppUser() {}
    public AppUser(String email, Instant now) { this.id = UUID.randomUUID(); this.email = email;  this.status = "ACTIVE"; this.locale = "en"; this.timezone = "UTC"; this.settingsJson = "{}"; this.settingsUpdatedAt = now; this.createdAt = now; }

}
