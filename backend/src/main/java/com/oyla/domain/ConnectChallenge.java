package com.oyla.domain;
import jakarta.persistence.*;
import java.time.LocalDate;
import java.util.UUID;
@Entity @Table(name="connect_challenge")
public class ConnectChallenge {
 @Id public UUID id;
 @Column(nullable=false) public UUID ownerId;
 @Column(nullable=false) public UUID friendId;
 @Column(nullable=false) public String type;
 @Column(nullable=false) public String status;
 @Column(nullable=false) public LocalDate startDate;
 @Column(nullable=false) public LocalDate endDate;
 @Column(nullable=false) public int goal;
 public ConnectChallenge() {}
}
