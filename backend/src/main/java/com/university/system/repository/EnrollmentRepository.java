package com.university.system.repository;

import com.university.system.entity.Enrollment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;
import java.util.Optional;

public interface EnrollmentRepository extends JpaRepository<Enrollment, Long> {

    List<Enrollment> findByStudent_UserId(Long studentId);

    @Query("SELECT e FROM Enrollment e WHERE e.student.userId = :studentId" +
           " AND e.course.semester.id = :semesterId")
    List<Enrollment> findByStudentAndSemester(Long studentId, Integer semesterId);

    List<Enrollment> findByCourse_Id(Integer courseId);

    Optional<Enrollment> findByStudent_UserIdAndCourse_Id(Long studentId, Integer courseId);

    boolean existsByStudent_UserIdAndCourse_Id(Long studentId, Integer courseId);

    @Query("SELECT COUNT(e) FROM Enrollment e WHERE e.course.id = :courseId AND e.status = 'ENROLLED'")
    long countEnrolledByCourseId(Integer courseId);
}
