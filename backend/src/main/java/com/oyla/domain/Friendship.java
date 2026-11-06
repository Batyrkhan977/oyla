package com.oyla.domain;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity @Table(name = "friendship", uniqueConstraints = @UniqueConstraint(columnNames = {"first_user_id", "second_user_id"}))
public class Friendship {
    @Id public UUID id;
    @Column(name = "first_user_id", nullable = false) public UUID firstUserId;
    @Column(name = "second_user_id", nullable = false) public UUID secondUserId;
    @Column(name = "requested_by_user_id", nullable = false) public UUID requestedByUserId;
    @Column(nullable = false) public String status;
    @Column(name = "created_at", nullable = false) public Instant createdAt;
    @Column(name = "updated_at", nullable = false) public Instant updatedAt;
    protected Friendship() {}

    public Friendship(UUID requester, UUID recipient, Instant now) {
        id = UUID.randomUUID();
        if (requester.toString().compareTo(recipient.toString()) < 0) { firstUserId = requester; secondUserId = recipient; }
        else { firstUserId = recipient; secondUserId = requester; }
        requestedByUserId = requester; status = "PENDING"; createdAt = now; updatedAt = now;
    }
    public boolean includes(UUID userId) { return firstUserId.equals(userId) || secondUserId.equals(userId); }
    public UUID other(UUID userId) { return firstUserId.equals(userId) ? secondUserId : firstUserId; }
}
