package com.oyla.api;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import java.sql.DriverManager;
import static org.junit.jupiter.api.Assertions.*;

@Testcontainers(disabledWithoutDocker=true)
class PostgresMigrationTest {
 @Container static PostgreSQLContainer<?> postgres=new PostgreSQLContainer<>("postgres:16-alpine");
 @Test void upgradesVersionFourWithoutRemovingHistory() throws Exception {
  Flyway.configure().dataSource(postgres.getJdbcUrl(),postgres.getUsername(),postgres.getPassword()).target("4").load().migrate();
  try(var connection=DriverManager.getConnection(postgres.getJdbcUrl(),postgres.getUsername(),postgres.getPassword());var statement=connection.createStatement()) {
   statement.execute("INSERT INTO app_user(id,email,status,locale,timezone,settings_json,settings_updated_at,created_at,friend_code) VALUES ('00000000-0000-0000-0000-000000000001','legacy@example.com','ACTIVE','en','UTC','{}',now(),now(),'23456789AB')");
   statement.execute("INSERT INTO exercise_result(id,user_id,installation_id,exercise_type,difficulty,algorithm_version,started_at,completed_at,correct_count,attempted_count,score,changed_at,practice,local_date) VALUES ('00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000003','colorWord',1,1,now(),now(),4,5,80,now(),true,current_date)");
  }
  Flyway.configure().dataSource(postgres.getJdbcUrl(),postgres.getUsername(),postgres.getPassword()).load().migrate();
  try(var connection=DriverManager.getConnection(postgres.getJdbcUrl(),postgres.getUsername(),postgres.getPassword());var statement=connection.createStatement()) {
   try(var result=statement.executeQuery("SELECT friend_code FROM app_user WHERE email='legacy@example.com'")){assertTrue(result.next());assertEquals("23456789AB",result.getString(1));}
   try(var result=statement.executeQuery("SELECT exercise_type FROM exercise_result")){assertTrue(result.next());assertEquals("colorWord",result.getString(1));}
   statement.execute("INSERT INTO day_record(id,user_id,kind,record_id,payload,revision,changed_at) VALUES ('00000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000001','day_settings','settings','{}',1,now())");
   statement.execute("DELETE FROM app_user WHERE email='legacy@example.com'");
   try(var result=statement.executeQuery("SELECT count(*) FROM day_record")){assertTrue(result.next());assertEquals(0,result.getInt(1));}
  }
 }
}
