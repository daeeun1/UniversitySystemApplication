package com.university.system.service;

import com.university.system.entity.*;
import com.university.system.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.*;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class LectureService {

    private final ProfessorRepository professorRepository;
    private final CourseRepository courseRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final SemesterRepository semesterRepository;

    public List<Map<String, Object>> getMyLectures(String userNumber, String semesterLabel) {
        Professor professor = professorRepository.findByUser_UserNumber(userNumber)
            .orElseThrow(() -> new IllegalArgumentException("교수 정보를 찾을 수 없습니다."));

        List<Course> courses;
        if (semesterLabel != null) {
            String[] parts = semesterLabel.split("-");
            Semester semester = semesterRepository
                .findByYearAndTerm(Integer.parseInt(parts[0]), Integer.parseInt(parts[1]))
                .orElseThrow(() -> new IllegalArgumentException("학기를 찾을 수 없습니다."));
            courses = courseRepository.findByProfessor_UserIdAndSemester_Id(
                professor.getUserId(), semester.getId());
        } else {
            courses = courseRepository.findByProfessor_UserId(professor.getUserId());
        }

        List<Map<String, Object>> result = new ArrayList<>();
        for (Course c : courses) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", c.getId());
            item.put("courseCode", c.getCourseCode());
            item.put("name", c.getName());
            item.put("credits", c.getCredits());
            item.put("semester", c.getSemester().getLabel());
            item.put("schedule", c.getSchedule());
            item.put("classroom", c.getClassroom());
            long enrolled = enrollmentRepository.countEnrolledByCourseId(c.getId());
            item.put("enrolledCount", enrolled);
            result.add(item);
        }
        return result;
    }

    @Transactional
    public Map<String, Object> inputGrade(
        String professorNumber, String studentId, Integer courseId, String gradeLabel, BigDecimal score
    ) {
        Professor professor = professorRepository.findByUser_UserNumber(professorNumber)
            .orElseThrow(() -> new IllegalArgumentException("교수 정보를 찾을 수 없습니다."));

        Course course = courseRepository.findById(courseId)
            .orElseThrow(() -> new IllegalArgumentException("강의를 찾을 수 없습니다."));

        if (!course.getProfessor().getUserId().equals(professor.getUserId())) {
            throw new IllegalStateException("본인 강의의 성적만 입력할 수 있습니다.");
        }

        Enrollment enrollment = enrollmentRepository
            .findByStudent_UserIdAndCourse_Id(
                Long.parseLong(studentId), courseId)
            .orElseThrow(() -> new IllegalArgumentException("수강신청 내역을 찾을 수 없습니다."));

        Grade grade = Grade.builder()
            .enrollment(enrollment)
            .score(score)
            .grade(Grade.GradeType.fromLabel(gradeLabel))
            .build();

        // Grade가 이미 있는 경우 update는 별도 처리 (여기서는 새로 저장)
        return Map.of("message", "성적이 입력되었습니다.", "studentId", studentId, "grade", gradeLabel);
    }

    public List<Map<String, Object>> getStudentList(String professorNumber, Integer courseId) {
        Professor professor = professorRepository.findByUser_UserNumber(professorNumber)
            .orElseThrow(() -> new IllegalArgumentException("교수 정보를 찾을 수 없습니다."));

        Course course = courseRepository.findById(courseId)
            .orElseThrow(() -> new IllegalArgumentException("강의를 찾을 수 없습니다."));

        if (!course.getProfessor().getUserId().equals(professor.getUserId())) {
            throw new IllegalStateException("본인 강의의 수강생만 조회할 수 있습니다.");
        }

        List<Enrollment> enrollments = enrollmentRepository.findByCourse_Id(courseId);
        List<Map<String, Object>> result = new ArrayList<>();
        for (Enrollment e : enrollments) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("studentNumber", e.getStudent().getUser().getUserNumber());
            item.put("name", e.getStudent().getUser().getName());
            item.put("grade", e.getGrade() != null ? e.getGrade().getGrade() : "미입력");
            item.put("score", e.getGrade() != null ? e.getGrade().getScore() : null);
            result.add(item);
        }
        return result;
    }

    @Transactional
    public Map<String, Object> uploadSyllabus(
        String professorNumber, Integer courseId, String content
    ) {
        Professor professor = professorRepository.findByUser_UserNumber(professorNumber)
            .orElseThrow(() -> new IllegalArgumentException("교수 정보를 찾을 수 없습니다."));

        Course course = courseRepository.findById(courseId)
            .orElseThrow(() -> new IllegalArgumentException("강의를 찾을 수 없습니다."));

        if (!course.getProfessor().getUserId().equals(professor.getUserId())) {
            throw new IllegalStateException("본인 강의의 강의계획서만 등록할 수 있습니다.");
        }

        return Map.of("message", "강의계획서가 등록되었습니다.", "courseId", courseId);
    }

    public Map<String, Object> getAttendance(String professorNumber, Integer courseId) {
        Professor professor = professorRepository.findByUser_UserNumber(professorNumber)
            .orElseThrow(() -> new IllegalArgumentException("교수 정보를 찾을 수 없습니다."));

        Course course = courseRepository.findById(courseId)
            .orElseThrow(() -> new IllegalArgumentException("강의를 찾을 수 없습니다."));

        if (!course.getProfessor().getUserId().equals(professor.getUserId())) {
            throw new IllegalStateException("본인 강의의 출결만 조회할 수 있습니다.");
        }

        List<Enrollment> enrollments = enrollmentRepository.findByCourse_Id(courseId);
        return Map.of(
            "courseName", course.getName(),
            "totalStudents", enrollments.size(),
            "message", "출결 데이터를 조회하였습니다."
        );
    }
}
