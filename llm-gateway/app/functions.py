import httpx
from typing import Any

# Gemini Function Calling 선언 목록 (20개)
FUNCTION_DECLARATIONS = [
    # ── 학사 관리 (학생) ──────────────────────────────────────────────
    {
        "name": "get_my_grades",
        "description": "현재 로그인한 학생의 성적을 조회합니다.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "semester": {"type": "STRING", "description": "학기 (예: 2024-1). 미입력 시 전체 조회"}
            }
        }
    },
    {
        "name": "get_course_list",
        "description": "수강 가능한 강의 목록을 조회합니다.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "semester": {"type": "STRING", "description": "학기 (예: 2024-1)"},
                "department": {"type": "STRING", "description": "학과명 (선택)"}
            },
            "required": ["semester"]
        }
    },
    {
        "name": "apply_for_course",
        "description": "수강신청을 합니다.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "course_id": {"type": "INTEGER", "description": "강의 ID"}
            },
            "required": ["course_id"]
        }
    },
    {
        "name": "drop_course",
        "description": "수강취소를 합니다.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "course_id": {"type": "INTEGER", "description": "강의 ID"}
            },
            "required": ["course_id"]
        }
    },
    {
        "name": "check_graduation_requirements",
        "description": "졸업요건 충족 여부를 확인합니다.",
        "parameters": {"type": "OBJECT", "properties": {}}
    },
    # ── 학적 관리 ──────────────────────────────────────────────────────
    {
        "name": "get_my_info",
        "description": "현재 로그인한 사용자의 개인 정보를 조회합니다.",
        "parameters": {"type": "OBJECT", "properties": {}}
    },
    {
        "name": "apply_for_leave",
        "description": "휴학 신청을 합니다.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "type": {"type": "STRING", "description": "휴학 유형 (일반/군휴학/질병)"},
                "reason": {"type": "STRING", "description": "휴학 사유"},
                "period": {"type": "STRING", "description": "휴학 기간 (예: 2024-1)"}
            },
            "required": ["type", "reason", "period"]
        }
    },
    {
        "name": "apply_for_reinstatement",
        "description": "복학 신청을 합니다.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "semester": {"type": "STRING", "description": "복학 학기 (예: 2024-2)"}
            },
            "required": ["semester"]
        }
    },
    {
        "name": "get_leave_status",
        "description": "휴학/복학 신청 현황을 조회합니다.",
        "parameters": {"type": "OBJECT", "properties": {}}
    },
    # ── 강의 관리 (교수) ──────────────────────────────────────────────
    {
        "name": "get_my_lectures",
        "description": "담당 강의 목록을 조회합니다. (교수 전용)",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "semester": {"type": "STRING", "description": "학기 (선택)"}
            }
        }
    },
    {
        "name": "input_grade",
        "description": "학생 성적을 입력합니다. (교수 전용)",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "student_id": {"type": "STRING", "description": "학번"},
                "course_id": {"type": "INTEGER", "description": "강의 ID"},
                "grade": {"type": "STRING", "description": "성적 (A+/A0/B+/B0/C+/C0/D+/D0/F)"},
                "score": {"type": "NUMBER", "description": "점수 (0-100)"}
            },
            "required": ["student_id", "course_id", "grade", "score"]
        }
    },
    {
        "name": "get_student_list",
        "description": "강의 수강생 목록을 조회합니다. (교수 전용)",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "course_id": {"type": "INTEGER", "description": "강의 ID"}
            },
            "required": ["course_id"]
        }
    },
    {
        "name": "upload_syllabus",
        "description": "강의계획서를 등록합니다. (교수 전용)",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "course_id": {"type": "INTEGER", "description": "강의 ID"},
                "content": {"type": "STRING", "description": "강의계획서 내용"}
            },
            "required": ["course_id", "content"]
        }
    },
    {
        "name": "get_attendance",
        "description": "수강생 출결 현황을 조회합니다. (교수 전용)",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "course_id": {"type": "INTEGER", "description": "강의 ID"}
            },
            "required": ["course_id"]
        }
    },
    # ── 시스템 관리 (관리자) ──────────────────────────────────────────
    {
        "name": "create_user",
        "description": "새 사용자 계정을 생성합니다. (관리자 전용)",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "role": {"type": "STRING", "description": "역할 (STUDENT/PROFESSOR/ADMIN)"},
                "name": {"type": "STRING", "description": "이름"},
                "email": {"type": "STRING", "description": "이메일"},
                "department": {"type": "STRING", "description": "학과"}
            },
            "required": ["role", "name", "email"]
        }
    },
    {
        "name": "assign_role_function",
        "description": "역할에 함수 권한을 부여합니다. (관리자 전용)",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "role_id": {"type": "INTEGER", "description": "역할 ID"},
                "function_id": {"type": "INTEGER", "description": "함수 ID"}
            },
            "required": ["role_id", "function_id"]
        }
    },
    {
        "name": "revoke_role_function",
        "description": "역할의 함수 권한을 회수합니다. (관리자 전용)",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "role_id": {"type": "INTEGER", "description": "역할 ID"},
                "function_id": {"type": "INTEGER", "description": "함수 ID"}
            },
            "required": ["role_id", "function_id"]
        }
    },
    {
        "name": "set_semester",
        "description": "학기 정보를 설정합니다. (관리자 전용)",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "year": {"type": "INTEGER", "description": "연도"},
                "term": {"type": "INTEGER", "description": "학기 (1 또는 2)"},
                "start_date": {"type": "STRING", "description": "시작일 (YYYY-MM-DD)"},
                "end_date": {"type": "STRING", "description": "종료일 (YYYY-MM-DD)"}
            },
            "required": ["year", "term", "start_date", "end_date"]
        }
    },
    {
        "name": "get_system_logs",
        "description": "시스템 로그를 조회합니다. (관리자 전용)",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "limit": {"type": "INTEGER", "description": "조회 건수 (기본 50)"}
            }
        }
    },
]

# 함수명 → 백엔드 API 경로 매핑
FUNCTION_API_MAP = {
    "get_my_grades":              ("GET",    "/api/academic/grades"),
    "get_course_list":            ("GET",    "/api/academic/courses"),
    "apply_for_course":           ("POST",   "/api/academic/courses/enroll"),
    "drop_course":                ("DELETE", "/api/academic/courses/enroll"),
    "check_graduation_requirements": ("GET", "/api/academic/graduation"),
    "get_my_info":                ("GET",    "/api/student/info"),
    "apply_for_leave":            ("POST",   "/api/student/leave"),
    "apply_for_reinstatement":    ("POST",   "/api/student/reinstatement"),
    "get_leave_status":           ("GET",    "/api/student/leave/status"),
    "get_my_lectures":            ("GET",    "/api/lecture/my"),
    "input_grade":                ("POST",   "/api/lecture/grades"),
    "get_student_list":           ("GET",    "/api/lecture/students"),
    "upload_syllabus":            ("POST",   "/api/lecture/syllabus"),
    "get_attendance":             ("GET",    "/api/lecture/attendance"),
    "create_user":                ("POST",   "/api/admin/users"),
    "assign_role_function":       ("POST",   "/api/admin/rbac/assign"),
    "revoke_role_function":       ("DELETE", "/api/admin/rbac/revoke"),
    "set_semester":               ("POST",   "/api/admin/semester"),
    "get_system_logs":            ("GET",    "/api/admin/logs"),
}


async def execute_function(
    function_name: str,
    args: dict,
    token: str,
    backend_url: str
) -> Any:
    """Function Calling 결과를 백엔드 API로 전달 (2차 RBAC는 백엔드가 처리)"""
    if function_name not in FUNCTION_API_MAP:
        return {"error": f"알 수 없는 함수: {function_name}"}

    method, path = FUNCTION_API_MAP[function_name]
    headers = {"Authorization": f"Bearer {token}"}

    async with httpx.AsyncClient() as client:
        if method == "GET":
            response = await client.get(
                f"{backend_url}{path}", params=args, headers=headers, timeout=15.0
            )
        elif method == "POST":
            response = await client.post(
                f"{backend_url}{path}", json=args, headers=headers, timeout=15.0
            )
        elif method == "DELETE":
            response = await client.delete(
                f"{backend_url}{path}", params=args, headers=headers, timeout=15.0
            )
        else:
            return {"error": "지원하지 않는 HTTP 메서드"}

        if response.status_code in (200, 201):
            return response.json()
        return {"error": f"API 오류 {response.status_code}: {response.text}"}
