package com.university.system.repository;

import com.university.system.entity.LeaveRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface LeaveRequestRepository extends JpaRepository<LeaveRequest, Integer> {
    List<LeaveRequest> findByStudent_UserId(Long studentId);
    List<LeaveRequest> findByStatus(LeaveRequest.RequestStatus status);
}
