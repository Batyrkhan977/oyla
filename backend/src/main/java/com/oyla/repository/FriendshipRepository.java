package com.oyla.repository;

import com.oyla.domain.Friendship;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.*;

public interface FriendshipRepository extends JpaRepository<Friendship, UUID> {
    @Query("select f from Friendship f where f.firstUserId = :userId or f.secondUserId = :userId order by f.updatedAt desc")
    List<Friendship> findAllForUser(@Param("userId") UUID userId);
    Optional<Friendship> findByFirstUserIdAndSecondUserId(UUID firstUserId, UUID secondUserId);
}
