package com.oyla.service;

import com.oyla.domain.*;
import com.oyla.repository.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import java.time.*;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class LocalDataBackfillTest {
    @Mock UserRepository users;
    @Mock ExerciseResultRepository results;

    @Test void preservesAccountsAndBackfillsHistoricalDates() {
        final AppUser user = new AppUser("old@example.com", Instant.now());
        user.friendCode = null;
        final ExerciseResult result = new ExerciseResult();
        result.completedAt = Instant.parse("2026-08-18T23:30:00Z");
        when(results.findAll()).thenReturn(List.of(result));

        new LocalDataBackfill(users, results).run(null);

        assertNull(user.friendCode);
        assertEquals(LocalDate.of(2026, 8, 18), result.localDate);
        verifyNoInteractions(users);
        verify(results).saveAll(any());
    }
}
