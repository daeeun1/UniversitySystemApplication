package com.university.system.service;

import com.university.system.entity.User;
import com.university.system.repository.SystemFunctionRepository;
import com.university.system.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RbacService {

    private final UserRepository userRepository;
    private final SystemFunctionRepository functionRepository;

    public List<String> getAllowedFunctions(String userNumber) {
        User user = userRepository.findByUserNumber(userNumber)
            .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        return functionRepository.findFunctionNamesByRoleId(user.getRole().getId());
    }

    public void assignFunction(Integer roleId, Integer functionId) {
        // role_functions 테이블에 직접 삽입 (네이티브 쿼리 또는 별도 엔티티로 처리)
        // 간결성을 위해 EntityManager를 직접 사용
        throw new UnsupportedOperationException("AdminService에서 처리합니다.");
    }
}
