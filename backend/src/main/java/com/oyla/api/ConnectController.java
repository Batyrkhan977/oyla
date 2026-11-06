package com.oyla.api;
import com.oyla.domain.*;
import com.oyla.repository.*;
import com.oyla.service.ConnectService;
import jakarta.persistence.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.time.*;
import java.util.*;

@RestController @RequestMapping("/api/v1/connect") @Transactional
public class ConnectController {
 @org.springframework.beans.factory.annotation.Value("${omirai.family.delivery-enabled:false}") private boolean familyDelivery;
 @org.springframework.beans.factory.annotation.Value("${omirai.family.public-url:}") private String publicUrl;
 private final EntityManager em; private final FriendshipRepository friends; private final UserRepository users; private final ConnectService service;
 public ConnectController(EntityManager em,FriendshipRepository friends,UserRepository users,ConnectService service){this.em=em;this.friends=friends;this.users=users;this.service=service;}
 private UUID id(Authentication a){UUID id=(UUID)a.getPrincipal();if(em.find(AppUser.class,id,LockModeType.PESSIMISTIC_WRITE)==null)throw new IllegalArgumentException("Unknown account");return id;}
 private Friendship friendship(UUID id,UUID user){var f=friends.findById(id).orElseThrow(()->new IllegalArgumentException("Unknown invitation"));if(!f.includes(user))throw new IllegalArgumentException("Not your invitation");return f;}
 private Friendship accepted(UUID id,UUID user){var f=friendship(id,user);if(!f.status.equals("ACCEPTED"))throw new IllegalArgumentException("Friendship is not accepted");service.requireEnabled(user);service.requireEnabled(f.other(user));return f;}
 @GetMapping public Map<String,Object> get(Authentication a){var user=id(a);var me=users.findById(user).orElseThrow();if(me.friendCode==null)me.friendCode=UUID.randomUUID().toString().replace("-","").substring(0,10).toUpperCase(Locale.ROOT);
 var list=friends.findAllForUser(user).stream().filter(f->!f.status.equals("REMOVED")).map(f->{var other=users.findById(f.other(user)).orElseThrow();return Map.of("id",f.id,"name",other.nickname==null?"ÖmirAI member":other.nickname,"incoming",!f.requestedByUserId.equals(user),"status",f.status,"activity",f.status.equals("ACCEPTED")&&service.settings(user).enabled?service.summary(other.id):Map.of());}).toList();
 var challenges=em.createQuery("from ConnectChallenge where ownerId=:id or friendId=:id",ConnectChallenge.class).setParameter("id",user).getResultList().stream().map(c->Map.of("id",c.id,"type",c.type,"status",c.status,"incoming",c.friendId.equals(user),"goal",c.goal,"endDate",c.endDate,"progress",service.challengeProgress(c,user))).toList();
 return Map.of("familyDeliveryConfigured",familyDelivery&&publicUrl.startsWith("https://"),"settings",service.own(user),"friendCode",me.friendCode,"friends",list,"challenges",challenges,"family",service.subscriptions(user).stream().map(s->Map.of("id",s.id,"recipient",s.recipient,"inactivityDays",s.inactivityDays,"weekly",s.weekly,"enabled",s.enabled,"unsubscribed",s.unsubscribed)).toList());}
 public record Settings(boolean enabled,boolean shareActivity,boolean showStreak){}
 @PutMapping("/settings") public void settings(Authentication a,@RequestBody Settings input){var s=service.settings(id(a));s.enabled=input.enabled();s.shareActivity=input.shareActivity();s.showStreak=input.showStreak();}
 public record FriendInput(@NotBlank @Size(min=10,max=10) String code){}
 @PostMapping("/friends") public void request(Authentication a,@Valid @RequestBody FriendInput input){var user=id(a);service.requireEnabled(user);var recipient=users.findByFriendCode(input.code().toUpperCase(Locale.ROOT)).orElseThrow(()->new IllegalArgumentException("Invitation code unavailable"));service.requireEnabled(recipient.id);if(user.equals(recipient.id))throw new IllegalArgumentException("Choose another member");var pair=new Friendship(user,recipient.id,Instant.now());var old=friends.findByFirstUserIdAndSecondUserId(pair.firstUserId,pair.secondUserId);if(old.isPresent()){var f=old.get();if(f.status.equals("REMOVED")){f.status="PENDING";f.requestedByUserId=user;f.updatedAt=Instant.now();}return;}friends.save(pair);}
 public record Action(@NotBlank String action){}
 @PostMapping("/friends/{friendshipId}") public void action(Authentication a,@PathVariable UUID friendshipId,@Valid @RequestBody Action input){var user=id(a);var f=friendship(friendshipId,user);switch(input.action()){
 case "accept" -> {service.requireEnabled(user);if(f.requestedByUserId.equals(user)||!f.status.equals("PENDING"))throw new IllegalArgumentException("Only the recipient can accept");f.status="ACCEPTED";}
 case "remove" -> f.status="REMOVED";
 case "invite" -> {accepted(friendshipId,user);var s=service.settings(user);if(s.lastInviteAt!=null&&s.lastInviteAt.isAfter(Instant.now().minusSeconds(86400)))throw new IllegalArgumentException("One invitation per day");s.lastInviteAt=Instant.now();var c=new ConnectChallenge();c.id=UUID.randomUUID();c.ownerId=user;c.friendId=f.other(user);c.type="active";c.status="PENDING";c.startDate=service.today(user);c.endDate=c.startDate;c.goal=1;em.persist(c);}
 case "gift" -> {accepted(friendshipId,user);var s=service.settings(user);var recipient=service.settings(f.other(user));if(s.freezes<1||recipient.freezes>=3||(s.lastGiftAt!=null&&s.lastGiftAt.isAfter(Instant.now().minusSeconds(604800))))throw new IllegalArgumentException("Gift unavailable");s.freezes--;recipient.freezes++;s.lastGiftAt=Instant.now();}
 default -> throw new IllegalArgumentException("Unknown action");}f.updatedAt=Instant.now();}
 @PostMapping("/freeze") public void freeze(Authentication a){service.freeze(id(a));}
 public record ChallengeInput(@NotNull UUID friendshipId,@NotBlank String type){}
 @PostMapping("/challenges") public void challenge(Authentication a,@Valid @RequestBody ChallengeInput input){var user=id(a);var f=accepted(input.friendshipId(),user);if(!Set.of("reading","active","walking","movement").contains(input.type()))throw new IllegalArgumentException("Unknown challenge");var open=em.createQuery("select count(c) from ConnectChallenge c where c.ownerId=:id and c.endDate>=:today",Long.class).setParameter("id",user).setParameter("today",service.today(user)).getSingleResult();if(open>=5)throw new IllegalArgumentException("Up to five current challenges");var c=new ConnectChallenge();c.id=UUID.randomUUID();c.ownerId=user;c.friendId=f.other(user);c.type=input.type();c.status="PENDING";c.startDate=service.today(user);c.endDate=c.startDate.plusDays(6);c.goal=switch(c.type){case "reading"->5;case "walking"->4;case "movement"->60;default->7;};em.persist(c);}
 @PostMapping("/challenges/{challengeId}") public void challengeAction(Authentication a,@PathVariable UUID challengeId,@RequestBody Action input){var c=em.find(ConnectChallenge.class,challengeId);if(c==null||!c.friendId.equals(id(a))||!c.status.equals("PENDING"))throw new IllegalArgumentException("Unknown pending invitation");service.requireEnabled(id(a));if(!Set.of("accept","decline").contains(input.action()))throw new IllegalArgumentException("Unknown action");c.status=input.action().equals("accept")?"ACCEPTED":"DECLINED";}
 public record FamilyInput(@NotBlank @Email @Size(max=254) String recipient,@Min(2) @Max(30) int inactivityDays,boolean weekly,boolean consent){}
 @PostMapping("/family") public void family(Authentication a,@Valid @RequestBody FamilyInput input){if(!input.consent())throw new IllegalArgumentException("Explicit consent required");var user=id(a);var email=input.recipient().strip().toLowerCase(Locale.ROOT);var list=service.subscriptions(user);var s=list.stream().filter(v->v.recipient.equals(email)).findFirst().orElse(null);if(s!=null&&s.unsubscribed)throw new IllegalArgumentException("Recipient opted out");if(s==null){if(list.size()>=5)throw new IllegalArgumentException("Up to five recipients");s=new FamilySubscription();s.id=UUID.randomUUID();s.ownerId=user;s.recipient=email;s.unsubscribeToken=UUID.randomUUID();s.consentAt=Instant.now();em.persist(s);}s.enabled=true;s.inactivityDays=input.inactivityDays();s.weekly=input.weekly();s.consentAt=Instant.now();}
 @DeleteMapping("/family/{subscriptionId}") public void revoke(Authentication a,@PathVariable UUID subscriptionId){var s=em.find(FamilySubscription.class,subscriptionId);if(s==null||!s.ownerId.equals(id(a)))throw new IllegalArgumentException("Unknown subscription");s.enabled=false;}
}
