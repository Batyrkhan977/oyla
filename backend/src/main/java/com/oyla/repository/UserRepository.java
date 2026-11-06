package com.oyla.repository;
import com.oyla.domain.AppUser;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface UserRepository extends JpaRepository<AppUser, UUID> {
    Optional<AppUser> findByEmail(String email);
    Optional<AppUser> findByFriendCode(String friendCode);
    boolean existsByFriendCode(String friendCode);
}
