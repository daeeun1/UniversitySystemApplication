package com.university.system.repository;

import com.university.system.entity.Course;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;

public interface CourseRepository extends JpaRepository<Course, Integer> {

    @Query("SELECT c FROM Course c WHERE c.semester.id = :semesterId" +
           " AND (:department IS NULL OR c.department.name = :department)")
    List<Course> findBySemesterAndDepartment(Integer semesterId, String department);

    List<Course> findByProfessor_UserId(Long professorId);

    List<Course> findByProfessor_UserIdAndSemester_Id(Long professorId, Integer semesterId);
}
