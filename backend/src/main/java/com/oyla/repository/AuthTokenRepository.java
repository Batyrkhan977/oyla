package com.oyla.repository;
import com.oyla.domain.AuthToken;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface AuthTokenRepository extends JpaRepository<AuthToken, UUID> {
    Optional<AuthToken> findByTokenHash(String tokenHash);
    List<AuthToken> findBySessionId(UUID sessionId);
}
