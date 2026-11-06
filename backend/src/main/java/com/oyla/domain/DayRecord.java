package com.oyla.domain;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

/** Account-owned versioned records. Payloads are validated at the API boundary. */
@Entity @Table(name="day_record", uniqueConstraints=@UniqueConstraint(columnNames={"user_id","kind","record_id"}))
public class DayRecord {
    @Id public UUID id;
    @Column(name="user_id",nullable=false) public UUID userId;
    @Column(nullable=false,length=32) public String kind;
    @Column(name="record_id",nullable=false,length=240) public String recordId;
    @Column(nullable=false,columnDefinition="text") public String payload;
    @Column(nullable=false) public long revision;
    @Column(name="changed_at",nullable=false) public Instant changedAt;
}
