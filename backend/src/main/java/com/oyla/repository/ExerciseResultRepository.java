package com.oyla.repository;
import com.oyla.domain.ExerciseResult;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.Instant;
import java.util.*;
public interface ExerciseResultRepository extends JpaRepository<ExerciseResult, UUID> {
    List<ExerciseResult> findByUserIdAndChangedAtAfterOrderByChangedAt(UUID userId, Instant since);
    List<ExerciseResult> findByUserIdOrderByCompletedAtDesc(UUID userId);
}
