package com.oyla.api;

import com.oyla.domain.*;
import com.oyla.repository.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.time.*;
import java.util.*;

@RestController @RequestMapping("/api/v1/sync")
public class SyncController {
    private final WorkoutRepository workouts;
    private final ExerciseResultRepository results;
    public SyncController(WorkoutRepository workouts, ExerciseResultRepository results) { this.workouts = workouts; this.results = results; }

    @PostMapping @Transactional
    public SyncResponse upload(Authentication authentication, @Valid @RequestBody SyncRequest request) {
        final UUID userId = (UUID) authentication.getPrincipal();
        final Instant changedAt = Instant.now();
        for (WorkoutInput input : request.workouts()) {
            final var existing = workouts.findById(input.id());
            if (existing.isPresent()) {
                if (!existing.get().userId.equals(userId)) throw new SyncConflictException();
                continue;
            }
            final Workout item = new Workout();
            item.id = input.id(); item.userId = userId; item.installationId = input.installationId(); item.localDate = input.localDate();
            item.startedAt = input.startedAt(); item.completedAt = input.completedAt(); item.completionState = input.completionState(); item.changedAt = changedAt;
            workouts.save(item);
        }
        for (ResultInput input : request.results()) {
            final var existing = results.findById(input.id());
            if (existing.isPresent()) {
                if (!existing.get().userId.equals(userId)) throw new SyncConflictException();
                continue;
            }
            if (input.workoutId() != null && workouts.findById(input.workoutId())
                    .filter(workout -> workout.userId.equals(userId)).isEmpty()) throw new SyncConflictException();
            final ExerciseResult item = new ExerciseResult();
            item.id = input.id(); item.workoutId = input.workoutId(); item.userId = userId; item.installationId = input.installationId();
            item.exerciseType = input.exerciseType(); item.difficulty = input.difficulty(); item.algorithmVersion = input.algorithmVersion();
            item.startedAt = input.startedAt(); item.completedAt = input.completedAt(); item.correctCount = input.correctCount();
            item.attemptedCount = input.attemptedCount(); item.score = input.score(); item.changedAt = changedAt;
            item.localDate = input.localDate() == null ? input.completedAt().atZone(ZoneOffset.UTC).toLocalDate() : input.localDate();
            item.practice = input.practice();
            results.save(item);
        }
        return download(userId, request.cursor());
    }

    @GetMapping
    public SyncResponse get(Authentication authentication, @RequestParam(required = false) String cursor) {
        return download((UUID) authentication.getPrincipal(), cursor);
    }

    private SyncResponse download(UUID userId, String cursor) {
        final Instant since = decodeCursor(cursor);
        final Instant snapshot = Instant.now();
        return new SyncResponse(
                encodeCursor(snapshot),
                workouts.findByUserIdAndChangedAtAfterOrderByChangedAt(userId, since).stream().map(WorkoutOutput::from).toList(),
                results.findByUserIdAndChangedAtAfterOrderByChangedAt(userId, since).stream().map(ResultOutput::from).toList());
    }

    private static String encodeCursor(Instant value) { return Base64.getUrlEncoder().withoutPadding().encodeToString(value.toString().getBytes(StandardCharsets.UTF_8)); }
    private static Instant decodeCursor(String cursor) {
        if (cursor == null || cursor.isBlank()) return Instant.EPOCH;
        try { return Instant.parse(new String(Base64.getUrlDecoder().decode(cursor), StandardCharsets.UTF_8)); }
        catch (RuntimeException invalid) { throw new IllegalArgumentException("Invalid sync cursor"); }
    }

    public record SyncRequest(String cursor, @NotNull @Size(max=500) List<@Valid WorkoutInput> workouts, @NotNull @Size(max=2000) List<@Valid ResultInput> results) {}
    public record WorkoutInput(@NotNull UUID id, @NotNull UUID installationId, @NotNull LocalDate localDate, @NotNull Instant startedAt, Instant completedAt, @NotNull @Pattern(regexp="IN_PROGRESS|COMPLETED|ABANDONED") String completionState) {}
    public record ResultInput(@NotNull UUID id, UUID workoutId, @NotNull UUID installationId, @NotNull @Pattern(regexp="quickSums|wordGarden|picturePairs|findTarget|runningTotal|colorWord") String exerciseType, @Min(1) @Max(10) int difficulty, @Min(1) int algorithmVersion, @NotNull Instant startedAt, @NotNull Instant completedAt, LocalDate localDate, @Min(0) int correctCount, @Min(1) int attemptedCount, @Min(0) @Max(100) int score, boolean practice) { @AssertTrue(message="correctCount must not exceed attemptedCount") public boolean countsValid() { return correctCount <= attemptedCount; } }
    public record SyncResponse(String cursor, List<WorkoutOutput> workouts, List<ResultOutput> results) {}
    public record WorkoutOutput(UUID id, UUID installationId, LocalDate localDate, Instant startedAt, Instant completedAt, String completionState, Instant changedAt) { static WorkoutOutput from(Workout w) { return new WorkoutOutput(w.id, w.installationId, w.localDate, w.startedAt, w.completedAt, w.completionState, w.changedAt); } }
    public record ResultOutput(UUID id, UUID workoutId, UUID installationId, String exerciseType, int difficulty, int algorithmVersion, Instant startedAt, Instant completedAt, LocalDate localDate, int correctCount, int attemptedCount, int score, boolean practice, Instant changedAt) { static ResultOutput from(ExerciseResult r) { return new ResultOutput(r.id, r.workoutId, r.installationId, r.exerciseType, r.difficulty, r.algorithmVersion, r.startedAt, r.completedAt, r.localDate, r.correctCount, r.attemptedCount, r.score, r.practice, r.changedAt); } }
    public static class SyncConflictException extends RuntimeException {}
}
