package com.oyla.domain;

import jakarta.persistence.*;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity @Table(name = "exercise_result")
public class ExerciseResult {
    @Id public UUID id;
    @Column(name = "workout_id") public UUID workoutId;
    @Column(name = "user_id", nullable = false) public UUID userId;
    @Column(name = "installation_id", nullable = false) public UUID installationId;
    @Column(name = "exercise_type", nullable = false) public String exerciseType;
    @Column(nullable = false) public int difficulty;
    @Column(name = "algorithm_version", nullable = false) public int algorithmVersion;
    @Column(name = "started_at", nullable = false) public Instant startedAt;
    @Column(name = "completed_at", nullable = false) public Instant completedAt;
    // See LocalDataBackfill: existing H2 rows need the column before values can
    // be populated. PostgreSQL's Flyway migration retains the NOT NULL rule.
    @Column(name = "local_date") public LocalDate localDate;
    @Column(name = "correct_count", nullable = false) public int correctCount;
    @Column(name = "attempted_count", nullable = false) public int attemptedCount;
    @Column(nullable = false) public int score;
    @Column(nullable = false) public boolean practice;
    @Column(name = "changed_at", nullable = false) public Instant changedAt;
    public ExerciseResult() {}
}
