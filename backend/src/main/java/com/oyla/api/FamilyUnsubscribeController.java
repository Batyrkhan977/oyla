package com.oyla.api;
import com.oyla.domain.FamilySubscription;
import jakarta.persistence.EntityManager;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;
@RestController @RequestMapping("/api/v1/family/unsubscribe")
public class FamilyUnsubscribeController {
 private final EntityManager em;
 public FamilyUnsubscribeController(EntityManager em){this.em=em;}
 @GetMapping(value="/{token}",produces="text/html;charset=UTF-8") public String page(@PathVariable UUID token){return "<!doctype html><html lang=\"en\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"><title>ÖmirAI email preferences</title><body><h1>Stop ÖmirAI updates</h1><form method=\"post\"><button style=\"font-size:20px;min-height:56px\">Unsubscribe</button></form></body></html>";}
 @PostMapping(value="/{token}",produces="text/plain;charset=UTF-8") @Transactional public String unsubscribe(@PathVariable UUID token){for(var s:em.createQuery("from FamilySubscription where unsubscribeToken=:token",FamilySubscription.class).setParameter("token",token).getResultList()){s.enabled=false;s.unsubscribed=true;}return "You will no longer receive these ÖmirAI updates.";}
}
