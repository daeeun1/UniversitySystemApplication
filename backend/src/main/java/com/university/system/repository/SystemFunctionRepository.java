package com.university.system.repository;

import com.university.system.entity.SystemFunction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;

public interface SystemFunctionRepository extends JpaRepository<SystemFunction, Integer> {

    @Query("SELECT f.name FROM Role r JOIN r.functions f WHERE r.id = :roleId")
    List<String> findFunctionNamesByRoleId(Integer roleId);
}
