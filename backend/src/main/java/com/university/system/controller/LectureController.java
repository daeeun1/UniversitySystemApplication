package com.university.system.controller;

import com.university.system.dto.ApiResponse;
import com.university.system.service.LectureService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/lecture")
@RequiredArgsConstructor
@Tag(name = "Lecture", description = "강의 관리 API (교수 전용)")
public class LectureController {

    private final LectureService lectureService;

    @GetMapping("/my")
    @Operation(summary = "담당 강의 목록 조회")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getMyLectures(
        @AuthenticationPrincipal UserDetails userDetails,
        @RequestParam(required = false) String semester
    ) {
        return ResponseEntity.ok(ApiResponse.ok(
            lectureService.getMyLectures(userDetails.getUsername(), semester)));
    }

    @PostMapping("/grades")
    @Operation(summary = "성적 입력")
    public ResponseEntity<ApiResponse<Map<String, Object>>> inputGrade(
        @AuthenticationPrincipal UserDetails userDetails,
        @RequestBody Map<String, Object> body
    ) {
        return ResponseEntity.ok(ApiResponse.ok(lectureService.inputGrade(
            userDetails.getUsername(),
            (String) body.get("student_id"),
            (Integer) body.get("course_id"),
            (String) body.get("grade"),
            new BigDecimal(body.get("score").toString())
        )));
    }

    @GetMapping("/students")
    @Operation(summary = "수강생 목록 조회")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getStudentList(
        @AuthenticationPrincipal UserDetails userDetails,
        @RequestParam Integer course_id
    ) {
        return ResponseEntity.ok(ApiResponse.ok(
            lectureService.getStudentList(userDetails.getUsername(), course_id)));
    }

    @PostMapping("/syllabus")
    @Operation(summary = "강의계획서 등록")
    public ResponseEntity<ApiResponse<Map<String, Object>>> uploadSyllabus(
        @AuthenticationPrincipal UserDetails userDetails,
        @RequestBody Map<String, Object> body
    ) {
        return ResponseEntity.ok(ApiResponse.ok(lectureService.uploadSyllabus(
            userDetails.getUsername(),
            (Integer) body.get("course_id"),
            (String) body.get("content")
        )));
    }

    @GetMapping("/attendance")
    @Operation(summary = "출결 현황 조회")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAttendance(
        @AuthenticationPrincipal UserDetails userDetails,
        @RequestParam Integer course_id
    ) {
        return ResponseEntity.ok(ApiResponse.ok(
            lectureService.getAttendance(userDetails.getUsername(), course_id)));
    }
}
