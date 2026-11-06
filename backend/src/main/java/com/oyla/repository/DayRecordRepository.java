package com.oyla.repository;
import com.oyla.domain.DayRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface DayRecordRepository extends JpaRepository<DayRecord,UUID> {
    List<DayRecord> findByUserIdOrderByChangedAtAsc(UUID userId);
    void deleteByUserId(UUID userId);
}
