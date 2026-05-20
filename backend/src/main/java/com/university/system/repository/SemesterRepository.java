package com.university.system.repository;

import com.university.system.entity.Semester;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface SemesterRepository extends JpaRepository<Semester, Integer> {
    Optional<Semester> findByIsCurrentTrue();
    Optional<Semester> findByYearAndTerm(Integer year, Integer term);
}
