package com.oyla.service;

import com.oyla.repository.ExerciseResultRepository;
import com.oyla.repository.UserRepository;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.ZoneOffset;

/** Safely upgrades persistent development H2 databases created before social features. */
@Component
@Profile("local")
public class LocalDataBackfill implements ApplicationRunner {
    private final UserRepository users;
    private final ExerciseResultRepository results;

    public LocalDataBackfill(UserRepository users, ExerciseResultRepository results) {
        this.users = users; this.results = results;
    }

    @Override @Transactional
    public void run(ApplicationArguments ignored) {
        final var history = results.findAll();
        for (final var result : history) {
            if (result.localDate == null && result.completedAt != null) {
                result.localDate = result.completedAt.atZone(ZoneOffset.UTC).toLocalDate();
            }
        }
        results.saveAll(history);
    }
}
