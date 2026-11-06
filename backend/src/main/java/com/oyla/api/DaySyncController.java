package com.oyla.api;

import com.fasterxml.jackson.databind.*;
import com.oyla.domain.*;
import com.oyla.repository.DayRecordRepository;
import jakarta.persistence.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.*;

@RestController @RequestMapping("/api/v1/sync/day")
public class DaySyncController {
    private static final Set<String> KINDS=Set.of("routines","occurrences","activity_events","reading_positions","reading_sessions","movement_sessions","recommendations","day_settings","music_sessions","music_progress","togyz_games","togyz_progress");
    private static final Set<String> ACTIVITIES=Set.of("cognitive","reading","exercise","walking","taiChi","yoga","pilates","custom","personal","other","music","togyz","stretching","dance");
    private static final Set<String> EVENTS=Set.of("SCHEDULED","STARTED","COMPLETED","SKIPPED","POSTPONED","REMINDER_SENT","REMINDER_OPENED","RECOMMENDATION_SHOWN","RECOMMENDATION_ACCEPTED","RECOMMENDATION_REJECTED");
    private final DayRecordRepository records;
    private final ObjectMapper mapper;
    private final EntityManager entities;
    public DaySyncController(DayRecordRepository records,ObjectMapper mapper,EntityManager entities){this.records=records;this.mapper=mapper;this.entities=entities;}
    public record Input(@NotBlank @Size(max=32) String kind,@NotBlank @Size(max=240) String id,@Min(0) long revision,@NotBlank @Size(max=30000) String payload){}
    public record Request(@NotNull @Size(max=2000) List<@Valid Input> records){}
    public record Output(String kind,String id,long revision,String payload) {static Output from(DayRecord r){return new Output(r.kind,r.recordId,r.revision,r.payload);}}
    public record Conflict(String kind,String id){}
    public record Response(String cursor,List<Output> records,List<Conflict> conflicts){}

    @PostMapping @Transactional
    public Response sync(Authentication auth,@Valid @RequestBody Request request) {
        final UUID owner=(UUID)auth.getPrincipal();
        // Serialize updates for one account, including first writes to a record.
        if(entities.find(AppUser.class,owner,LockModeType.PESSIMISTIC_WRITE)==null) throw new IllegalArgumentException("Unknown account");
        final var conflicts=new ArrayList<Conflict>();
        final Set<String> seen=new HashSet<>();
        for(final Input input:request.records()) {
            final JsonNode payload=validate(input);
            if(!seen.add(input.kind()+":"+input.id())) throw new IllegalArgumentException("Duplicate record in request");
            final UUID key=UUID.nameUUIDFromBytes((owner+":"+input.kind()+":"+input.id()).getBytes(StandardCharsets.UTF_8));
            final var existing=records.findById(key);
            if(existing.isPresent()) {
                final DayRecord current=existing.get();
                if(parse(current.payload).equals(payload)) continue; // Lost-response retries are idempotent.
                if(input.kind().equals("activity_events") || input.kind().equals("movement_sessions") || input.kind().equals("music_sessions") || input.revision()!=current.revision) {
                    conflicts.add(new Conflict(input.kind(),input.id()));continue;
                }
                current.payload=payload.toString();current.revision++;current.changedAt=Instant.now();records.save(current);
            } else {
                if(input.revision()!=0) {conflicts.add(new Conflict(input.kind(),input.id()));continue;}
                final DayRecord record=new DayRecord();record.id=key;record.userId=owner;record.kind=input.kind();record.recordId=input.id();record.payload=payload.toString();record.revision=1;record.changedAt=Instant.now();records.save(record);
            }
        }
        records.flush();
        // A full account snapshot prevents cursor-boundary omissions. Cursor is
        // informational in MVP; uploads are bounded and clients batch them.
        return new Response(Base64.getUrlEncoder().withoutPadding().encodeToString(Instant.now().toString().getBytes(StandardCharsets.UTF_8)),records.findByUserIdOrderByChangedAtAsc(owner).stream().map(Output::from).toList(),conflicts);
    }
    private JsonNode parse(String value){try{return mapper.readTree(value);}catch(Exception ignored){throw new IllegalArgumentException("Invalid record JSON");}}
    private JsonNode validate(Input input){
        if(!KINDS.contains(input.kind()))throw new IllegalArgumentException("Unknown record kind");
        final JsonNode j=parse(input.payload());
        if(!j.isObject() || !input.id().equals(j.path("id").asText()))throw new IllegalArgumentException("Record ID mismatch");
        if(j.has("userId"))throw new IllegalArgumentException("Owner is assigned by the server");
        switch(input.kind()) {
            case "routines" -> routine(j);
            case "occurrences" -> {routine(j.path("routine"));oneOf(j,"status",Set.of("scheduled","started","completed","postponed","skipped"));number(j,"minutes",0,1440);text(j,"date",10);text(j,"scheduledAt",64);}
            case "activity_events" -> {oneOf(j,"eventType",EVENTS);oneOf(j,"activityType",ACTIVITIES);text(j,"activityId",240);text(j,"routineId",240);text(j,"at",64);number(j,"duration",0,1440);}
            case "reading_positions" -> {text(j,"bookId",240);number(j,"position",0,1000000);}
            case "reading_sessions" -> {text(j,"bookId",240);number(j,"seconds",0,86400*7);oneOf(j,"mode",Set.of("reading","tts","aloud"));text(j,"date",10);}
            case "movement_sessions" -> {oneOf(j,"kind",Set.of("exercise","walking","taiChi","yoga","pilates","stretching","dance"));number(j,"minutes",0,1440);text(j,"completedAt",64);}
            case "recommendations" -> {text(j,"routineId",240);oneOf(j,"type",Set.of("postponed","time","duration","reminder","movement"));if(!j.path("basis").isObject())throw new IllegalArgumentException("Missing recommendation basis");}
            case "music_sessions" -> {text(j,"mode",80);number(j,"seconds",0,86400);number(j,"level",1,8);text(j,"date",10);text(j,"completedAt",64);}
            case "music_progress" -> {number(j,"level",1,8);number(j,"completed",0,100000);}
            case "togyz_games" -> {number(j,"turn",0,1);int total=0;
              for(String field:List.of("pits","kazan","tuzdyk")){var values=j.path(field);if(!values.isArray()||values.size()!=(field.equals("pits")?18:2))throw new IllegalArgumentException("Invalid board");for(var v:values){if(!v.isIntegralNumber()||v.asInt()<(field.equals("tuzdyk")?-1:0)||v.asInt()>(field.equals("tuzdyk")?17:162))throw new IllegalArgumentException("Invalid stones");if(!field.equals("tuzdyk"))total+=v.asInt();}}
              if(total!=162||!j.path("finished").isBoolean())throw new IllegalArgumentException("Invalid board total");
              int a=j.path("tuzdyk").get(0).asInt(),b=j.path("tuzdyk").get(1).asInt();
              if((a>=0&&(a<9||a%9==8||j.path("pits").get(a).asInt()!=0))||(b>=0&&(b>=9||b%9==8||j.path("pits").get(b).asInt()!=0))||(a>=0&&b>=0&&a%9==b%9))throw new IllegalArgumentException("Invalid tuzdyk");}
            case "togyz_progress" -> {number(j,"lesson",0,7);number(j,"difficulty",0,2);}
            case "day_settings" -> {if(!input.id().equals("settings"))throw new IllegalArgumentException("Invalid settings ID");}
            default -> throw new IllegalArgumentException("Unsupported record");
        }
        return j;
    }
    private void routine(JsonNode j){text(j,"id",240);text(j,"title",80);oneOf(j,"kind",ACTIVITIES);number(j,"minute",0,1439);number(j,"duration",1,240);final JsonNode days=j.path("weekdays");if(!days.isArray() || days.isEmpty() || days.size()>7)throw new IllegalArgumentException("Invalid weekdays");final Set<Integer> unique=new HashSet<>();for(JsonNode d:days){if(!d.isIntegralNumber()||d.intValue()<1||d.intValue()>7||!unique.add(d.intValue()))throw new IllegalArgumentException("Invalid weekday");}}
    private void text(JsonNode j,String field,int max){if(!j.path(field).isTextual()||j.path(field).asText().isBlank()||j.path(field).asText().length()>max)throw new IllegalArgumentException("Invalid "+field);}
    private void number(JsonNode j,String field,int min,int max){if(!j.path(field).isIntegralNumber()||j.path(field).asLong()<min||j.path(field).asLong()>max)throw new IllegalArgumentException("Invalid "+field);}
    private void oneOf(JsonNode j,String field,Set<String> values){if(!values.contains(j.path(field).asText()))throw new IllegalArgumentException("Invalid "+field);}
}
