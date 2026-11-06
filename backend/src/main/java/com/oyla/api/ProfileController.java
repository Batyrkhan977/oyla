package com.oyla.api;

import com.oyla.domain.AppUser;
import com.oyla.repository.UserRepository;
import com.oyla.repository.DayRecordRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.UUID;

@RestController @RequestMapping("/api/v1/me")
public class ProfileController {
    @jakarta.persistence.PersistenceContext private jakarta.persistence.EntityManager entities;
    private final UserRepository users;
    private final DayRecordRepository dayRecords;
    public ProfileController(UserRepository users, DayRecordRepository dayRecords) { this.users = users; this.dayRecords = dayRecords; }
    @GetMapping @Transactional public Profile get(Authentication auth) { return Profile.from(user(auth)); }
    @PatchMapping @Transactional public Profile patch(Authentication auth, @Valid @RequestBody ProfilePatch patch) {
        final AppUser user = user(auth);
        if (patch.nickname() != null) user.nickname = patch.nickname().strip();
        if (patch.locale() != null) user.locale = patch.locale();
        if (patch.timezone() != null) user.timezone = patch.timezone();
        if (patch.settingsJson() != null) { user.settingsJson = patch.settingsJson(); user.settingsUpdatedAt = Instant.now(); }
        return Profile.from(users.save(user));
    }
    @DeleteMapping @ResponseStatus(HttpStatus.NO_CONTENT) @Transactional public void delete(Authentication auth) { final UUID id=(UUID)auth.getPrincipal();
      entities.createQuery("delete from FamilySubscription where ownerId=:id").setParameter("id",id).executeUpdate();
      entities.createQuery("delete from ConnectChallenge where ownerId=:id or friendId=:id").setParameter("id",id).executeUpdate();
      entities.createQuery("delete from ConnectSettings where id=:id").setParameter("id",id).executeUpdate();
      entities.createQuery("delete from Friendship where firstUserId=:id or secondUserId=:id").setParameter("id",id).executeUpdate();
      dayRecords.deleteByUserId(id); users.deleteById(id); }
    private AppUser user(Authentication auth) {
        final AppUser user = users.findById((UUID) auth.getPrincipal()).orElseThrow();
        return user;
    }
    public record Profile(UUID id, String email, String nickname, String locale, String timezone, String settingsJson, Instant settingsUpdatedAt) { static Profile from(AppUser u) { return new Profile(u.id, u.email, u.nickname, u.locale, u.timezone, u.settingsJson, u.settingsUpdatedAt); } }
    public record ProfilePatch(@Size(max=80) String nickname, @Size(max=16) String locale, @Size(max=64) String timezone, @Size(max=10000) String settingsJson) {}
}
