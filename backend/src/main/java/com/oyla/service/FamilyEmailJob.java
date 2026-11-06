package com.oyla.service;
import com.oyla.domain.*;
import jakarta.persistence.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.*;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;

@Component @EnableScheduling
public class FamilyEmailJob {
 private final EntityManager em;private final ConnectService service;private final JavaMailSender mail;private final String from,publicUrl;private final boolean enabled;
 public FamilyEmailJob(EntityManager em,ConnectService service,JavaMailSender mail,@Value("${oyla.mail.from}")String from,@Value("${omirai.family.public-url:}")String publicUrl,@Value("${omirai.family.delivery-enabled:false}")boolean enabled){this.em=em;this.service=service;this.mail=mail;this.from=from;this.publicUrl=publicUrl;this.enabled=enabled;}
 @Scheduled(fixedDelay=3600000,initialDelay=60000) @Transactional
 public void deliver(){
  if(!enabled||!publicUrl.startsWith("https://"))return;
  var now=Instant.now();var today=LocalDate.now(ZoneOffset.UTC);
  for(var candidate:em.createQuery("from FamilySubscription where enabled=true and unsubscribed=false",FamilySubscription.class).getResultList()){
   var s=em.find(FamilySubscription.class,candidate.id,LockModeType.PESSIMISTIC_WRITE);em.refresh(s);
   if(!s.enabled||s.unsubscribed)continue;
   var days=service.days(s.ownerId,"active",LocalDate.of(2000,1,1));
   var last=days.isEmpty()?s.consentAt.atZone(ZoneOffset.UTC).toLocalDate():days.last();
   // Offline activity is unknown: wording always refers to received app activity.
   var sinceConsent=s.consentAt.atZone(ZoneOffset.UTC).toLocalDate();if(last.isBefore(sinceConsent))last=sinceConsent;
   var inactive=!last.plusDays(s.inactivityDays).isAfter(today)&&(s.lastInactivitySent==null||s.lastInactivitySent.atZone(ZoneOffset.UTC).toLocalDate().isBefore(last));
   var weekly=s.weekly&&(s.lastWeeklySent==null?s.consentAt:s.lastWeeklySent).isBefore(now.minusSeconds(604800));
   if(!inactive&&!weekly)continue;
   var message=new SimpleMailMessage();message.setFrom(from);message.setTo(s.recipient);message.setSubject("ÖmirAI activity update");
   var body=inactive?"No new activity has been received in ÖmirAI for "+s.inactivityDays+" days. Activity recorded offline may not have synchronized. This message describes app usage only.":"ÖmirAI received activity on "+service.days(s.ownerId,"active",today.minusDays(6)).size()+" days this week.";
   message.setText(body+"\nThe user chose to share this update with you.\nStop these emails: "+publicUrl+"/api/v1/family/unsubscribe/"+s.unsubscribeToken);
   try{mail.send(message);if(inactive)s.lastInactivitySent=now;if(weekly)s.lastWeeklySent=now;}catch(org.springframework.mail.MailException ignored){/* Retry at the next scheduled run; never log recipient addresses. */}
  }
 }
}
