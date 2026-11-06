package com.oyla.repository;
import com.oyla.domain.Workout;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.Instant;
import java.util.*;
public interface WorkoutRepository extends JpaRepository<Workout, UUID> { List<Workout> findByUserIdAndChangedAtAfterOrderByChangedAt(UUID userId, Instant since); }
