package com.oyla.domain;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
@Entity @Table(name="family_subscription")
public class FamilySubscription {
 @Id public UUID id;
 @Column(nullable=false) public UUID ownerId;
 @Column(nullable=false) public String recipient;
 @Column(nullable=false) public int inactivityDays;
 @Column(nullable=false) public boolean weekly;
 @Column(nullable=false) public boolean enabled;
 @Column(nullable=false) public boolean unsubscribed;
 @Column(nullable=false,unique=true) public UUID unsubscribeToken;
 @Column(nullable=false) public Instant consentAt;
 public Instant lastInactivitySent;
 public Instant lastWeeklySent;
 public FamilySubscription() {}
}
