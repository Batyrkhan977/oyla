package com.oyla.api;
import com.oyla.domain.AppUser;
import com.oyla.repository.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import java.time.Instant;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(properties={"spring.datasource.url=jdbc:h2:mem:daytest;MODE=PostgreSQL;DB_CLOSE_DELAY=-1", "spring.datasource.driver-class-name=org.h2.Driver", "spring.jpa.hibernate.ddl-auto=create-drop", "spring.flyway.enabled=false"})
class DaySyncControllerTest {
 @Autowired DaySyncController controller;
 @Autowired UserRepository users;
 @Autowired ProfileController profiles;
 @Autowired DayRecordRepository records;
 Authentication account(){final var user=users.save(new AppUser(java.util.UUID.randomUUID()+"@example.com",Instant.now()));return new UsernamePasswordAuthenticationToken(user.id,null,List.of());}
 DaySyncController.Input routine(long revision,int minute){return new DaySyncController.Input("routines","r1",revision,"{\"id\":\"r1\",\"title\":\"Reading\",\"kind\":\"reading\",\"weekdays\":[1,2],\"minute\":"+minute+",\"duration\":10,\"reminder\":false,\"deleted\":false}");}
 DaySyncController.Response upload(Authentication user,DaySyncController.Input input){return controller.sync(user,new DaySyncController.Request(List.of(input)));}
 @Test void retriesAndRevisionConflictsPreserveChosenSchedule(){
  final var user=account();
  assertEquals(1,upload(user,routine(0,540)).records().getFirst().revision());
  assertEquals(1,upload(user,routine(0,540)).records().getFirst().revision());
  assertEquals(2,upload(user,routine(1,600)).records().getFirst().revision());
  final var conflict=upload(user,routine(1,840));assertEquals(1,conflict.conflicts().size());assertTrue(conflict.records().getFirst().payload().contains("600"));
  assertEquals(3,upload(user,routine(2,840)).records().getFirst().revision());
 }
 @Test void accountsCannotReadEachOthersRecordsAndDeletionIncludesDayRecords(){
  final var a=account();final var b=account();upload(a,routine(0,540));
  assertTrue(controller.sync(b,new DaySyncController.Request(List.of())).records().isEmpty());
  upload(b,routine(0,600));profiles.delete(a);
  assertFalse(users.existsById((java.util.UUID)a.getPrincipal()));
  assertTrue(records.findByUserIdOrderByChangedAtAsc((java.util.UUID)a.getPrincipal()).isEmpty());
  assertEquals(1,controller.sync(b,new DaySyncController.Request(List.of())).records().size());
 }
 @Test void eventsAreImmutableAndInvalidActivitiesAreRejected(){
  final var user=account();
  final String payload="{\"id\":\"e1\",\"activityId\":\"o1\",\"routineId\":\"r1\",\"activityType\":\"reading\",\"eventType\":\"STARTED\",\"at\":\"2026-09-12T09:00:00Z\",\"duration\":0}";
  upload(user,new DaySyncController.Input("activity_events","e1",0,payload));
  assertEquals(1,upload(user,new DaySyncController.Input("activity_events","e1",1,payload.replace("STARTED","COMPLETED"))).conflicts().size());
  assertThrows(IllegalArgumentException.class,()->upload(user,new DaySyncController.Input("routines","r1",0,routine(0,540).payload().replace("reading","healthScore"))));
 }
}
