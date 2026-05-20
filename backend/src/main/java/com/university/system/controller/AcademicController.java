package com.university.system.controller;

import com.university.system.dto.ApiResponse;
import com.university.system.service.AcademicService;
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
@RequestMapping("/api/academic")
@RequiredArgsConstructor
@Tag(name = "Academic", description = "학사 관리 API")
public class AcademicController {

    private final AcademicService academicService;

    @GetMapping("/grades")
    @Operation(summary = "성적 조회")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getMyGrades(
        @AuthenticationPrincipal UserDetails userDetails,
        @RequestParam(required = false) String semester
    ) {
        return ResponseEntity.ok(ApiResponse.ok(
            academicService.getMyGrades(userDetails.getUsername(), semester)));
    }

    @GetMapping("/courses")
    @Operation(summary = "강의 목록 조회")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getCourseList(
        @RequestParam String semester,
        @RequestParam(required = false) String department
    ) {
        return ResponseEntity.ok(ApiResponse.ok(
            academicService.getCourseList(semester, department)));
    }

    @PostMapping("/courses/enroll")
    @Operation(summary = "수강신청")
    public ResponseEntity<ApiResponse<Map<String, Object>>> applyForCourse(
        @AuthenticationPrincipal UserDetails userDetails,
        @RequestBody Map<String, Integer> body
    ) {
        return ResponseEntity.ok(ApiResponse.ok(
            academicService.applyForCourse(userDetails.getUsername(), body.get("course_id"))));
    }

    @DeleteMapping("/courses/enroll")
    @Operation(summary = "수강취소")
    public ResponseEntity<ApiResponse<Map<String, Object>>> dropCourse(
        @AuthenticationPrincipal UserDetails userDetails,
        @RequestParam Integer course_id
    ) {
        return ResponseEntity.ok(ApiResponse.ok(
            academicService.dropCourse(userDetails.getUsername(), course_id)));
    }

    @GetMapping("/graduation")
    @Operation(summary = "졸업요건 확인")
    public ResponseEntity<ApiResponse<Map<String, Object>>> checkGraduation(
        @AuthenticationPrincipal UserDetails userDetails
    ) {
        return ResponseEntity.ok(ApiResponse.ok(
            academicService.checkGraduationRequirements(userDetails.getUsername())));
    }
}
