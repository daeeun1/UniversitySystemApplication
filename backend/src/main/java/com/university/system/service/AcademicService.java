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
public class AcademicService {

    private final StudentRepository studentRepository;
    private final SemesterRepository semesterRepository;
    private final CourseRepository courseRepository;
    private final EnrollmentRepository enrollmentRepository;

    public List<Map<String, Object>> getMyGrades(String userNumber, String semesterLabel) {
        Student student = studentRepository.findByUser_UserNumber(userNumber)
            .orElseThrow(() -> new IllegalArgumentException("학생 정보를 찾을 수 없습니다."));

        List<Enrollment> enrollments;
        if (semesterLabel != null) {
            String[] parts = semesterLabel.split("-");
            Semester semester = semesterRepository
                .findByYearAndTerm(Integer.parseInt(parts[0]), Integer.parseInt(parts[1]))
                .orElseThrow(() -> new IllegalArgumentException("학기를 찾을 수 없습니다."));
            enrollments = enrollmentRepository.findByStudentAndSemester(
                student.getUserId(), semester.getId());
        } else {
            enrollments = enrollmentRepository.findByStudent_UserId(student.getUserId());
        }

        List<Map<String, Object>> result = new ArrayList<>();
        for (Enrollment e : enrollments) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("courseName", e.getCourse().getName());
            item.put("courseCode", e.getCourse().getCourseCode());
            item.put("credits", e.getCourse().getCredits());
            item.put("semester", e.getCourse().getSemester().getLabel());
            if (e.getGrade() != null) {
                item.put("grade", e.getGrade().getGrade() != null ?
                    e.getGrade().getGrade().getLabel() : null);
                item.put("score", e.getGrade().getScore());
            } else {
                item.put("grade", "미입력");
                item.put("score", null);
            }
            result.add(item);
        }
        return result;
    }

    public List<Map<String, Object>> getCourseList(String semesterLabel, String department) {
        String[] parts = semesterLabel.split("-");
        Semester semester = semesterRepository
            .findByYearAndTerm(Integer.parseInt(parts[0]), Integer.parseInt(parts[1]))
            .orElseThrow(() -> new IllegalArgumentException("학기를 찾을 수 없습니다."));

        List<Course> courses = courseRepository
            .findBySemesterAndDepartment(semester.getId(), department);

        List<Map<String, Object>> result = new ArrayList<>();
        for (Course c : courses) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", c.getId());
            item.put("courseCode", c.getCourseCode());
            item.put("name", c.getName());
            item.put("credits", c.getCredits());
            item.put("professor", c.getProfessor().getUser().getName());
            item.put("department", c.getDepartment().getName());
            item.put("schedule", c.getSchedule());
            item.put("classroom", c.getClassroom());
            long enrolled = enrollmentRepository.countEnrolledByCourseId(c.getId());
            item.put("enrolledCount", enrolled);
            item.put("maxStudents", c.getMaxStudents());
            result.add(item);
        }
        return result;
    }

    @Transactional
    public Map<String, Object> applyForCourse(String userNumber, Integer courseId) {
        Student student = studentRepository.findByUser_UserNumber(userNumber)
            .orElseThrow(() -> new IllegalArgumentException("학생 정보를 찾을 수 없습니다."));

        if (enrollmentRepository.existsByStudent_UserIdAndCourse_Id(student.getUserId(), courseId)) {
            throw new IllegalStateException("이미 수강신청한 강의입니다.");
        }

        Course course = courseRepository.findById(courseId)
            .orElseThrow(() -> new IllegalArgumentException("강의를 찾을 수 없습니다."));

        long enrolled = enrollmentRepository.countEnrolledByCourseId(courseId);
        if (enrolled >= course.getMaxStudents()) {
            throw new IllegalStateException("수강 정원이 초과되었습니다.");
        }

        Enrollment enrollment = Enrollment.builder()
            .student(student)
            .course(course)
            .status(Enrollment.EnrollmentStatus.ENROLLED)
            .build();
        enrollmentRepository.save(enrollment);

        return Map.of("message", "수강신청이 완료되었습니다.", "courseName", course.getName());
    }

    @Transactional
    public Map<String, Object> dropCourse(String userNumber, Integer courseId) {
        Student student = studentRepository.findByUser_UserNumber(userNumber)
            .orElseThrow(() -> new IllegalArgumentException("학생 정보를 찾을 수 없습니다."));

        Enrollment enrollment = enrollmentRepository
            .findByStudent_UserIdAndCourse_Id(student.getUserId(), courseId)
            .orElseThrow(() -> new IllegalStateException("수강신청 내역이 없습니다."));

        enrollmentRepository.delete(enrollment);
        return Map.of("message", "수강취소가 완료되었습니다.");
    }

    public Map<String, Object> checkGraduationRequirements(String userNumber) {
        Student student = studentRepository.findByUser_UserNumber(userNumber)
            .orElseThrow(() -> new IllegalArgumentException("학생 정보를 찾을 수 없습니다."));

        int totalCredits = student.getTotalCredits();
        int requiredCredits = 130;
        boolean satisfied = totalCredits >= requiredCredits;

        return Map.of(
            "studentName", student.getUser().getName(),
            "totalCredits", totalCredits,
            "requiredCredits", requiredCredits,
            "satisfied", satisfied,
            "remaining", Math.max(0, requiredCredits - totalCredits)
        );
    }
}
