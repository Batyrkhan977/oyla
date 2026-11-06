package com.oyla.domain;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
@Entity @Table(name="connect_settings")
public class ConnectSettings {
 @Id public UUID id;
 @Column(nullable=false) public boolean enabled;
 @Column(nullable=false) public boolean shareActivity;
 @Column(nullable=false) public boolean showStreak=true;
 @Column(nullable=false) public int freezes=0;
 @Column(nullable=false,columnDefinition="text") public String frozenDays="";
 @Column(nullable=false) public int earnedFreezes=0;
 public Instant lastInviteAt;
 public Instant lastGiftAt;
 public ConnectSettings() {}
 public ConnectSettings(UUID id){this.id=id;}
}
