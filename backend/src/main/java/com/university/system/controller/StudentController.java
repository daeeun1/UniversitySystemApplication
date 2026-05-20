package com.university.system.controller;

import com.university.system.dto.ApiResponse;
import com.university.system.service.StudentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/student")
@RequiredArgsConstructor
@Tag(name = "Student", description = "학적 관리 API")
public class StudentController {

    private final StudentService studentService;

    @GetMapping("/info")
    @Operation(summary = "개인정보 조회")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getMyInfo(
        @AuthenticationPrincipal UserDetails userDetails
    ) {
        return ResponseEntity.ok(ApiResponse.ok(
            studentService.getMyInfo(userDetails.getUsername())));
    }

    @PostMapping("/leave")
    @Operation(summary = "휴학 신청")
    public ResponseEntity<ApiResponse<Map<String, Object>>> applyForLeave(
        @AuthenticationPrincipal UserDetails userDetails,
        @RequestBody Map<String, String> body
    ) {
        return ResponseEntity.ok(ApiResponse.ok(studentService.applyForLeave(
            userDetails.getUsername(),
            body.get("type"),
            body.get("reason"),
            body.get("period")
        )));
    }

    @PostMapping("/reinstatement")
    @Operation(summary = "복학 신청")
    public ResponseEntity<ApiResponse<Map<String, Object>>> applyForReinstatement(
        @AuthenticationPrincipal UserDetails userDetails,
        @RequestBody Map<String, String> body
    ) {
        return ResponseEntity.ok(ApiResponse.ok(studentService.applyForReinstatement(
            userDetails.getUsername(), body.get("semester"))));
    }

    @GetMapping("/leave/status")
    @Operation(summary = "휴학/복학 현황 조회")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getLeaveStatus(
        @AuthenticationPrincipal UserDetails userDetails
    ) {
        return ResponseEntity.ok(ApiResponse.ok(
            studentService.getLeaveStatus(userDetails.getUsername())));
    }
}
