package com.university.system.repository;

import com.university.system.entity.SystemLog;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SystemLogRepository extends JpaRepository<SystemLog, Long> {
    List<SystemLog> findByOrderByCreatedAtDesc(Pageable pageable);
    List<SystemLog> findByIsBlockedTrue(Pageable pageable);
}
