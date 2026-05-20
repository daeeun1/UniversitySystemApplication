package com.university.system.controller;

import com.university.system.dto.ApiResponse;
import com.university.system.service.RbacService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/rbac")
@RequiredArgsConstructor
@Tag(name = "RBAC", description = "역할 기반 접근 제어 API")
public class RbacController {

    private final RbacService rbacService;

    @GetMapping("/allowed-functions")
    @Operation(summary = "허용 함수 목록", description = "현재 사용자 역할의 허용된 Function Calling 목록 반환 (LLM Gateway용)")
    public ResponseEntity<List<String>> getAllowedFunctions(
        @AuthenticationPrincipal UserDetails userDetails
    ) {
        List<String> functions = rbacService.getAllowedFunctions(userDetails.getUsername());
        return ResponseEntity.ok(functions);
    }
}
