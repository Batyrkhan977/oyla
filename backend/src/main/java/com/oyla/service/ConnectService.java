package com.oyla.service;

import com.fasterxml.jackson.databind.*;
import com.oyla.domain.*;
import com.oyla.repository.*;
import jakarta.persistence.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.*;

@Service @Transactional
public class ConnectService {
 private final EntityManager em;
 private final DayRecordRepository records;
 private final ObjectMapper mapper;
 public ConnectService(EntityManager em,DayRecordRepository records,ObjectMapper mapper){this.em=em;this.records=records;this.mapper=mapper;}
 public ConnectSettings settings(UUID id){var s=em.find(ConnectSettings.class,id);if(s==null){s=new ConnectSettings(id);em.persist(s);}return s;}
 public void requireEnabled(UUID id){if(!settings(id).enabled)throw new IllegalArgumentException("Enable Connect first");}
 public LocalDate today(UUID id){var user=em.find(AppUser.class,id);try{return LocalDate.now(ZoneId.of(user.timezone));}catch(Exception ignored){return LocalDate.now(ZoneOffset.UTC);}}
 public SortedSet<LocalDate> days(UUID id,String type, LocalDate since){
   final SortedSet<LocalDate> days=new TreeSet<>();
   for(var r:records.findByUserIdOrderByChangedAtAsc(id))try{
     if(!r.kind.equals("activity_events"))continue;
     var j=mapper.readTree(r.payload);
     if(!j.path("eventType").asText().equals("COMPLETED"))continue;
     var kind=j.path("activityType").asText();
     if(!type.equals("active")&&!type.equals(kind))continue;
     var date=LocalDate.parse(j.path("at").asText().substring(0,10));
     if(!date.isBefore(since)&&!date.isAfter(today(id)))days.add(date);
   }catch(Exception ignored){}
   return days;
 }
 public int movementMinutes(UUID id,LocalDate since,LocalDate until){int total=0;for(var r:records.findByUserIdOrderByChangedAtAsc(id))try{if(!r.kind.equals("movement_sessions"))continue;var j=mapper.readTree(r.payload);var date=LocalDate.parse(j.path("completedAt").asText().substring(0,10));if(!date.isBefore(since)&&!date.isAfter(today(id))&&!date.isAfter(until))total+=j.path("minutes").asInt();}catch(Exception ignored){}return total;}
 public int streak(UUID id){var s=settings(id);var days=days(id,"active",today(id).minusYears(2));for(var date:s.frozenDays.split(","))if(!date.isBlank())days.add(LocalDate.parse(date));var date=today(id);if(!days.contains(date))date=date.minusDays(1);int count=0;while(days.contains(date)){count++;date=date.minusDays(1);}return count;}
 public Map<String,Object> summary(UUID id){var s=settings(id);if(!s.enabled||!s.shareActivity)return Map.of("sharing",false);var days=days(id,"active",today(id).minusDays(6));return Map.of("sharing",true,"activeDays",days.size(),"activeToday",days.contains(today(id)),"streak",s.showStreak?streak(id):0);}
 public Map<String,Object> own(UUID id){var s=settings(id);int earned=days(id,"active",LocalDate.of(2000,1,1)).size()/7;if(earned>s.earnedFreezes){s.freezes=Math.min(3,s.freezes+earned-s.earnedFreezes);s.earnedFreezes=earned;}return Map.of("enabled",s.enabled,"shareActivity",s.shareActivity,"showStreak",s.showStreak,"streak",s.showStreak?streak(id):0,"freezes",s.freezes);}
 public void freeze(UUID id){var s=settings(id);var yesterday=today(id).minusDays(1);if(s.freezes<=0||days(id,"active",yesterday).contains(yesterday)||Arrays.asList(s.frozenDays.split(",")).contains(yesterday.toString()))throw new IllegalArgumentException("No freeze available for yesterday");s.freezes--;s.frozenDays+=yesterday+",";}
 public List<FamilySubscription> subscriptions(UUID id){return em.createQuery("from FamilySubscription where ownerId=:id",FamilySubscription.class).setParameter("id",id).getResultList();}
 public int challengeProgress(ConnectChallenge c,UUID id){return c.type.equals("movement")?movementMinutes(id,c.startDate,c.endDate):days(id,c.type,c.startDate).headSet(c.endDate.plusDays(1)).size();}
}
