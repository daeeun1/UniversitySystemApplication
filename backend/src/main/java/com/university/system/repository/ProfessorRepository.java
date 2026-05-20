package com.university.system.repository;

import com.university.system.entity.Professor;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface ProfessorRepository extends JpaRepository<Professor, Long> {
    Optional<Professor> findByUser_UserNumber(String userNumber);
}
