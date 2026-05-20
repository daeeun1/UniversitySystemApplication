package com.university.system.service;

import com.university.system.entity.*;
import com.university.system.repository.*;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.util.*;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AdminService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final SystemFunctionRepository functionRepository;
    private final SemesterRepository semesterRepository;
    private final SystemLogRepository systemLogRepository;
    private final LeaveRequestRepository leaveRequestRepository;
    private final PasswordEncoder passwordEncoder;

    @PersistenceContext
    private EntityManager em;

    @Transactional
    public Map<String, Object> createUser(
        String roleName, String name, String email, String department
    ) {
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("이미 사용 중인 이메일입니다.");
        }

        Role role = roleRepository.findByName(roleName.toUpperCase())
            .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 역할입니다."));

        String userNumber = generateUserNumber(roleName);
        String tempPassword = passwordEncoder.encode("Temp1234!");

        User user = User.builder()
            .userNumber(userNumber)
            .passwordHash(tempPassword)
            .name(name)
            .email(email)
            .role(role)
            .isActive(true)
            .build();

        userRepository.save(user);
        return Map.of(
            "message", "사용자가 생성되었습니다.",
            "userNumber", userNumber,
            "tempPassword", "Temp1234!"
        );
    }

    @Transactional
    public Map<String, Object> assignRoleFunction(Integer roleId, Integer functionId) {
        em.createNativeQuery(
            "INSERT IGNORE INTO role_functions (role_id, function_id) VALUES (?, ?)")
            .setParameter(1, roleId)
            .setParameter(2, functionId)
            .executeUpdate();
        return Map.of("message", "권한이 부여되었습니다.", "roleId", roleId, "functionId", functionId);
    }

    @Transactional
    public Map<String, Object> revokeRoleFunction(Integer roleId, Integer functionId) {
        em.createNativeQuery(
            "DELETE FROM role_functions WHERE role_id = ? AND function_id = ?")
            .setParameter(1, roleId)
            .setParameter(2, functionId)
            .executeUpdate();
        return Map.of("message", "권한이 회수되었습니다.", "roleId", roleId, "functionId", functionId);
    }

    @Transactional
    public Map<String, Object> setSemester(
        Integer year, Integer term, String startDate, String endDate
    ) {
        semesterRepository.findByIsCurrentTrue().ifPresent(s -> {
            em.createNativeQuery("UPDATE semesters SET is_current = false WHERE id = ?")
              .setParameter(1, s.getId()).executeUpdate();
        });

        Semester existing = semesterRepository.findByYearAndTerm(year, term).orElse(null);
        if (existing != null) {
            em.createNativeQuery(
                "UPDATE semesters SET start_date=?, end_date=?, is_current=true WHERE id=?")
                .setParameter(1, startDate)
                .setParameter(2, endDate)
                .setParameter(3, existing.getId())
                .executeUpdate();
        } else {
            em.createNativeQuery(
                "INSERT INTO semesters (year, term, start_date, end_date, is_current) VALUES (?,?,?,?,true)")
                .setParameter(1, year)
                .setParameter(2, term)
                .setParameter(3, startDate)
                .setParameter(4, endDate)
                .executeUpdate();
        }
        return Map.of("message", "학기가 설정되었습니다.", "semester", year + "-" + term);
    }

    public List<Map<String, Object>> getSystemLogs(Integer limit) {
        int size = limit != null ? limit : 50;
        List<SystemLog> logs = systemLogRepository
            .findByOrderByCreatedAtDesc(PageRequest.of(0, size));

        List<Map<String, Object>> result = new ArrayList<>();
        for (SystemLog log : logs) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", log.getId());
            item.put("user", log.getUser() != null ? log.getUser().getUserNumber() : "unknown");
            item.put("functionName", log.getFunctionName());
            item.put("apiPath", log.getApiPath());
            item.put("responseStatus", log.getResponseStatus());
            item.put("rbacLayer", log.getRbacLayer());
            item.put("isBlocked", log.getIsBlocked());
            item.put("createdAt", log.getCreatedAt());
            result.add(item);
        }
        return result;
    }

    private String generateUserNumber(String roleName) {
        String prefix = switch (roleName.toUpperCase()) {
            case "STUDENT" -> "S";
            case "PROFESSOR" -> "P";
            case "ADMIN" -> "A";
            default -> "U";
        };
        return prefix + System.currentTimeMillis() % 100000000;
    }
}
