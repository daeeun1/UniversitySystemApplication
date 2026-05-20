package com.university.system.controller;

import com.university.system.dto.ApiResponse;
import com.university.system.service.AdminService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@Tag(name = "Admin", description = "시스템 관리 API (관리자 전용)")
public class AdminController {

    private final AdminService adminService;

    @PostMapping("/users")
    @Operation(summary = "사용자 생성")
    public ResponseEntity<ApiResponse<Map<String, Object>>> createUser(
        @RequestBody Map<String, String> body
    ) {
        return ResponseEntity.ok(ApiResponse.ok(adminService.createUser(
            body.get("role"), body.get("name"), body.get("email"), body.get("department"))));
    }

    @PostMapping("/rbac/assign")
    @Operation(summary = "역할 권한 부여")
    public ResponseEntity<ApiResponse<Map<String, Object>>> assignRoleFunction(
        @RequestBody Map<String, Integer> body
    ) {
        return ResponseEntity.ok(ApiResponse.ok(
            adminService.assignRoleFunction(body.get("role_id"), body.get("function_id"))));
    }

    @DeleteMapping("/rbac/revoke")
    @Operation(summary = "역할 권한 회수")
    public ResponseEntity<ApiResponse<Map<String, Object>>> revokeRoleFunction(
        @RequestParam Integer role_id, @RequestParam Integer function_id
    ) {
        return ResponseEntity.ok(ApiResponse.ok(
            adminService.revokeRoleFunction(role_id, function_id)));
    }

    @PostMapping("/semester")
    @Operation(summary = "학기 설정")
    public ResponseEntity<ApiResponse<Map<String, Object>>> setSemester(
        @RequestBody Map<String, Object> body
    ) {
        return ResponseEntity.ok(ApiResponse.ok(adminService.setSemester(
            (Integer) body.get("year"),
            (Integer) body.get("term"),
            (String) body.get("start_date"),
            (String) body.get("end_date")
        )));
    }

    @GetMapping("/logs")
    @Operation(summary = "시스템 로그 조회")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getSystemLogs(
        @RequestParam(required = false) Integer limit
    ) {
        return ResponseEntity.ok(ApiResponse.ok(adminService.getSystemLogs(limit)));
    }
}
