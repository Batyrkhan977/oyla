package com.oyla.domain;

import jakarta.persistence.*;
import java.time.*;
import java.util.UUID;

@Entity @Table(name = "workout")
public class Workout {
    @Id public UUID id;
    @Column(name = "user_id", nullable = false) public UUID userId;
    @Column(name = "installation_id", nullable = false) public UUID installationId;
    @Column(name = "local_date", nullable = false) public LocalDate localDate;
    @Column(name = "started_at", nullable = false) public Instant startedAt;
    @Column(name = "completed_at") public Instant completedAt;
    @Column(name = "completion_state", nullable = false) public String completionState;
    @Column(name = "changed_at", nullable = false) public Instant changedAt;
    public Workout() {}
}
