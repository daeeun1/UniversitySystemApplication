package com.university.system.repository;

import com.university.system.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUserNumber(String userNumber);
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
}
