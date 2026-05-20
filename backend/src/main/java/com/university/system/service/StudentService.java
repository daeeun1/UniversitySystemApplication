package com.university.system.service;

import com.university.system.entity.*;
import com.university.system.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class StudentService {

    private final StudentRepository studentRepository;
    private final SemesterRepository semesterRepository;
    private final LeaveRequestRepository leaveRequestRepository;
    private final UserRepository userRepository;

    public Map<String, Object> getMyInfo(String userNumber) {
        User user = userRepository.findByUserNumber(userNumber)
            .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        Map<String, Object> info = new LinkedHashMap<>();
        info.put("userNumber", user.getUserNumber());
        info.put("name", user.getName());
        info.put("email", user.getEmail());
        info.put("phone", user.getPhone());
        info.put("role", user.getRole().getName());

        studentRepository.findByUser_UserNumber(userNumber).ifPresent(s -> {
            info.put("admissionYear", s.getAdmissionYear());
            info.put("grade", s.getGrade());
            info.put("status", s.getStatus().name());
            info.put("totalCredits", s.getTotalCredits());
            info.put("mainDepartment", s.getMainDepartment().getName());
        });

        return info;
    }

    @Transactional
    public Map<String, Object> applyForLeave(
        String userNumber, String type, String reason, String period
    ) {
        Student student = studentRepository.findByUser_UserNumber(userNumber)
            .orElseThrow(() -> new IllegalArgumentException("학생 정보를 찾을 수 없습니다."));

        if (student.getStatus() != Student.StudentStatus.ENROLLED) {
            throw new IllegalStateException("재학 중인 학생만 휴학 신청이 가능합니다.");
        }

        String[] parts = period.split("-");
        Semester targetSemester = semesterRepository
            .findByYearAndTerm(Integer.parseInt(parts[0]), Integer.parseInt(parts[1]))
            .orElseThrow(() -> new IllegalArgumentException("대상 학기를 찾을 수 없습니다."));

        LeaveRequest request = LeaveRequest.builder()
            .student(student)
            .type(LeaveRequest.LeaveType.valueOf(type.toUpperCase()))
            .reason(reason)
            .targetSemester(targetSemester)
            .requestType(LeaveRequest.RequestType.LEAVE)
            .status(LeaveRequest.RequestStatus.PENDING)
            .build();

        leaveRequestRepository.save(request);
        return Map.of("message", "휴학 신청이 접수되었습니다.", "status", "PENDING");
    }

    @Transactional
    public Map<String, Object> applyForReinstatement(String userNumber, String semester) {
        Student student = studentRepository.findByUser_UserNumber(userNumber)
            .orElseThrow(() -> new IllegalArgumentException("학생 정보를 찾을 수 없습니다."));

        if (student.getStatus() != Student.StudentStatus.ON_LEAVE) {
            throw new IllegalStateException("휴학 중인 학생만 복학 신청이 가능합니다.");
        }

        String[] parts = semester.split("-");
        Semester targetSemester = semesterRepository
            .findByYearAndTerm(Integer.parseInt(parts[0]), Integer.parseInt(parts[1]))
            .orElseThrow(() -> new IllegalArgumentException("대상 학기를 찾을 수 없습니다."));

        LeaveRequest request = LeaveRequest.builder()
            .student(student)
            .type(LeaveRequest.LeaveType.GENERAL)
            .reason("복학 신청")
            .targetSemester(targetSemester)
            .requestType(LeaveRequest.RequestType.REINSTATEMENT)
            .status(LeaveRequest.RequestStatus.PENDING)
            .build();

        leaveRequestRepository.save(request);
        return Map.of("message", "복학 신청이 접수되었습니다.", "status", "PENDING");
    }

    public List<Map<String, Object>> getLeaveStatus(String userNumber) {
        Student student = studentRepository.findByUser_UserNumber(userNumber)
            .orElseThrow(() -> new IllegalArgumentException("학생 정보를 찾을 수 없습니다."));

        List<LeaveRequest> requests = leaveRequestRepository
            .findByStudent_UserId(student.getUserId());

        List<Map<String, Object>> result = new ArrayList<>();
        for (LeaveRequest r : requests) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", r.getId());
            item.put("requestType", r.getRequestType().name());
            item.put("type", r.getType().name());
            item.put("reason", r.getReason());
            item.put("status", r.getStatus().name());
            item.put("targetSemester", r.getTargetSemester() != null ?
                r.getTargetSemester().getLabel() : null);
            item.put("createdAt", r.getCreatedAt());
            result.add(item);
        }
        return result;
    }
}
