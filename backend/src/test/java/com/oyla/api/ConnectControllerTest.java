package com.oyla.api;
import com.oyla.domain.*;
import com.oyla.repository.*;
import com.oyla.service.*;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@SpringBootTest(properties={"management.health.mail.enabled=false","spring.datasource.url=jdbc:h2:mem:connecttest;MODE=PostgreSQL;DB_CLOSE_DELAY=-1","spring.datasource.driver-class-name=org.h2.Driver","spring.jpa.hibernate.ddl-auto=create-drop","spring.flyway.enabled=false","omirai.family.delivery-enabled=true","omirai.family.public-url=https://example.invalid"})
@Transactional
class ConnectControllerTest {
 @Autowired ConnectController controller; @Autowired ConnectService service; @Autowired UserRepository users;
 @Autowired FriendshipRepository friends; @Autowired EntityManager em; @Autowired FamilyEmailJob job;
 @Autowired FamilyUnsubscribeController unsubscribe; @Autowired DaySyncController sync; @Autowired ProfileController profile;
 @MockBean JavaMailSender mail;
 Authentication account(){var u=users.save(new AppUser(UUID.randomUUID()+"@example.com",Instant.now()));return new UsernamePasswordAuthenticationToken(u.id,null,List.of());}
 UUID id(Authentication a){return (UUID)a.getPrincipal();}
 void enable(Authentication a){controller.settings(a,new ConnectController.Settings(true,true,true));}
 Friendship request(Authentication a,Authentication b){enable(a);enable(b);var code=(String)controller.get(b).get("friendCode");controller.request(a,new ConnectController.FriendInput(code));return friends.findAllForUser(id(a)).getFirst();}
 @Test void mutualConsentAndOwnershipAreEnforced(){var a=account();var b=account();var outsider=account();var f=request(a,b);assertThrows(IllegalArgumentException.class,()->controller.action(a,f.id,new ConnectController.Action("accept")));assertThrows(IllegalArgumentException.class,()->controller.action(outsider,f.id,new ConnectController.Action("accept")));controller.action(b,f.id,new ConnectController.Action("accept"));assertEquals("ACCEPTED",friends.findById(f.id).orElseThrow().status);controller.settings(b,new ConnectController.Settings(false,true,true));assertEquals(Map.of("sharing",false),service.summary(id(b)));}
 @Test void socialSummaryContainsNoPrivateActivityFields(){var a=account();enable(a);var summary=service.summary(id(a));assertEquals(Set.of("sharing","activeDays","activeToday","streak"),summary.keySet());controller.settings(a,new ConnectController.Settings(true,false,false));assertEquals(Map.of("sharing",false),service.summary(id(a)));}
 @Test void invitationsAreLimitedAndChallengesNeedRecipientAcceptance(){var a=account();var b=account();var f=request(a,b);controller.action(b,f.id,new ConnectController.Action("accept"));controller.action(a,f.id,new ConnectController.Action("invite"));assertThrows(IllegalArgumentException.class,()->controller.action(a,f.id,new ConnectController.Action("invite")));controller.challenge(a,new ConnectController.ChallengeInput(f.id,"reading"));var c=em.createQuery("from ConnectChallenge where type='reading'",ConnectChallenge.class).getSingleResult();assertEquals("PENDING",c.status);assertThrows(IllegalArgumentException.class,()->controller.challengeAction(a,c.id,new ConnectController.Action("accept")));controller.challengeAction(b,c.id,new ConnectController.Action("accept"));assertEquals("ACCEPTED",c.status);}
 @Test void noEmailWithoutConsentAndUnsubscribeCannotBeOverridden(){var a=account();assertThrows(IllegalArgumentException.class,()->controller.family(a,new ConnectController.FamilyInput("family@example.com",3,false,false)));controller.family(a,new ConnectController.FamilyInput("family@example.com",3,false,true));var s=service.subscriptions(id(a)).getFirst();unsubscribe.unsubscribe(s.unsubscribeToken);assertFalse(s.enabled);assertThrows(IllegalArgumentException.class,()->controller.family(a,new ConnectController.FamilyInput("family@example.com",3,false,true)));job.deliver();verifyNoInteractions(mail);}
 @Test void inactivityEmailIsLimitedToAppUsageAndSentOncePerEpisode(){var a=account();controller.family(a,new ConnectController.FamilyInput("family@example.com",3,false,true));var s=service.subscriptions(id(a)).getFirst();s.consentAt=Instant.now().minusSeconds(86400*5);em.flush();job.deliver();job.deliver();var capture=org.mockito.ArgumentCaptor.forClass(SimpleMailMessage.class);verify(mail,times(1)).send(capture.capture());var body=capture.getValue().getText();assertTrue(body.contains("received in ÖmirAI"));assertTrue(body.contains("unsubscribe/"));assertFalse(body.contains("score"));assertFalse(body.contains("medicine"));}
 @Test void musicSyncIsIdempotentAndOwnedByAccount(){var a=account();var b=account();String payload="{\"id\":\"m1\",\"mode\":\"piano:note\",\"seconds\":30,\"level\":1,\"date\":\"2026-09-27\",\"completedAt\":\"2026-09-27T10:00:00Z\"}";var r=new DaySyncController.Request(List.of(new DaySyncController.Input("music_sessions","m1",0,payload)));sync.sync(a,r);assertEquals(1,sync.sync(a,r).records().size());assertTrue(sync.sync(b,new DaySyncController.Request(List.of())).records().isEmpty());}
 @Test void deletionRemovesSubscriptionsAndSocialRecords(){var a=account();var b=account();request(a,b);controller.family(a,new ConnectController.FamilyInput("family@example.com",3,false,true));profile.delete(a);assertTrue(service.subscriptions(id(a)).isEmpty());assertTrue(friends.findAllForUser(id(a)).isEmpty());}
}
