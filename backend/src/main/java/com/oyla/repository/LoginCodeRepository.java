package com.oyla.repository;
import com.oyla.domain.LoginCode;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface LoginCodeRepository extends JpaRepository<LoginCode, UUID> { Optional<LoginCode> findFirstByEmailOrderByCreatedAtDesc(String email); }
