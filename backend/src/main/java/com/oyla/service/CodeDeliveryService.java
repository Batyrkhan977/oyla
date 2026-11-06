package com.oyla.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class CodeDeliveryService {
    private final JavaMailSender mail;
    private final String from;
    public CodeDeliveryService(JavaMailSender mail, @Value("${oyla.mail.from}") String from) { this.mail = mail; this.from = from; }
    public void send(String email, String code) {
        final SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from); message.setTo(email); message.setSubject("Your ÖmirAI sign-in code");
        message.setText("Your ÖmirAI sign-in code is " + code + ". It expires in 10 minutes. If you did not request it, you can ignore this message.");
        mail.send(message);
    }
}
