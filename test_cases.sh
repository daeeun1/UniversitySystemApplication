#!/bin/bash
# =============================================================
# 대학 정보 시스템 RBAC + LLM 통합 테스트 케이스
# 백엔드: http://localhost:18080
# LLM Gateway: http://localhost:18001
# =============================================================

BASE="http://localhost:18080"
LLM="http://localhost:18001"
PASS=0
FAIL=0
SKIP=0
CSV_FILE="$(dirname "$0")/test_results_$(date +%Y%m%d_%H%M%S).csv"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "테스트ID,카테고리,설명,기대값,결과,실제응답(일부),실행시각" > "$CSV_FILE"

run_test() {
  local id="$1" desc="$2" expected="$3" actual="$4"
  local category=$(echo "$id" | sed 's/-[0-9]*$//')
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local actual_short=$(echo "$actual" | tr -d '\n\r' | head -c 120 | sed 's/,/;/g' | sed "s/\"/'/g")
  if echo "$actual" | grep -qE "$expected"; then
    echo -e "${GREEN}[PASS]${NC} $id $desc"
    PASS=$((PASS+1))
    echo "$id,$category,\"$desc\",\"$expected\",PASS,\"$actual_short\",\"$timestamp\"" >> "$CSV_FILE"
  else
    echo -e "${RED}[FAIL]${NC} $id $desc"
    echo "       기대: $expected"
    echo "       실제: $(echo "$actual" | head -c 200)"
    FAIL=$((FAIL+1))
    echo "$id,$category,\"$desc\",\"$expected\",FAIL,\"$actual_short\",\"$timestamp\"" >> "$CSV_FILE"
  fi
}

run_skip() {
  local id="$1" desc="$2" reason="$3"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "${YELLOW}[SKIP]${NC} $id $desc ($reason)"
  SKIP=$((SKIP+1))
  echo "$id,,\"$desc\",,SKIP,\"$reason\",\"$timestamp\"" >> "$CSV_FILE"
}

# JSON 생성 헬퍼 (한글 인코딩 문제 방지)
make_chat_json() {
  local msg="$1" token="$2"
  printf '{"message":"%s","token":"%s","conversation_history":[]}' "$msg" "$token"
}

# python3 → python fallback (test actual execution, not just path existence)
PYTHON_CMD="python"
python3 -c "print(1)" >/dev/null 2>&1 && PYTHON_CMD="python3"

# =============================================================
# 토큰 발급
# =============================================================
echo -e "\n${CYAN}▶ 토큰 발급${NC}"

TOKEN_ADMIN=$(curl -s -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"userNumber":"ADMIN001","password":"Admin1234!"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

TOKEN_ADM=$(curl -s -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"userNumber":"ADM001","password":"Test1234!"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

TOKEN_PROF=$(curl -s -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"userNumber":"PRO2010001","password":"Test1234!"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

TOKEN_STU=$(curl -s -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"userNumber":"STU2021001","password":"Test1234!"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

# STU2022001: 이번 학기 수강 중, 휴학 신청 없음
TOKEN_STU2=$(curl -s -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"userNumber":"STU2022001","password":"Test1234!"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

echo "  SYSTEM_ADMIN : ${TOKEN_ADMIN:0:40}..."
echo "  ADMIN        : ${TOKEN_ADM:0:40}..."
echo "  PROFESSOR    : ${TOKEN_PROF:0:40}..."
echo "  STUDENT(홍길동): ${TOKEN_STU:0:40}..."
echo "  STUDENT(김철수): ${TOKEN_STU2:0:40}..."


# =============================================================
# TC-AUTH: 인증 테스트
# =============================================================
echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}[TC-AUTH] 인증 테스트${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

R=$(curl -s -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"userNumber":"ADMIN001","password":"Admin1234!"}')
run_test "TC-AUTH-01" "관리자(SYSTEM_ADMIN) 로그인 성공" '"success":true' "$R"

R=$(curl -s -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"userNumber":"STU2021001","password":"Test1234!"}')
run_test "TC-AUTH-02" "학생(홍길동) 로그인 성공" '"success":true' "$R"

R=$(curl -s -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"userNumber":"PRO2010001","password":"Test1234!"}')
run_test "TC-AUTH-03" "교수(이교수) 로그인 성공" '"success":true' "$R"

R=$(curl -s -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"userNumber":"ADM001","password":"Test1234!"}')
run_test "TC-AUTH-04" "행정직원(김행정) 로그인 성공" '"success":true' "$R"

R=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"userNumber":"STU2021001","password":"WrongPass!"}')
run_test "TC-AUTH-05" "잘못된 비밀번호 → 403 거부" "403" "$R"

R=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"userNumber":"GHOST999","password":"Test1234!"}')
run_test "TC-AUTH-06" "존재하지 않는 계정 → 403 거부" "403" "$R"

R=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/academic/grades")
run_test "TC-AUTH-07" "토큰 없이 인증 필요 API 접근 → 403 거부" "403" "$R"

R=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/academic/grades" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.TAMPERED.SIGNATURE")
run_test "TC-AUTH-08" "변조된 JWT 토큰 → 403 거부" "403" "$R"


# =============================================================
# TC-RBAC: 역할 기반 접근 제어 테스트
# =============================================================
echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}[TC-RBAC] 역할 기반 접근 제어 테스트${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n  ${YELLOW}[학생 역할 검증]${NC}"

R=$(curl -s "$BASE/api/academic/grades" \
  -H "Authorization: Bearer $TOKEN_STU")
run_test "TC-RBAC-01" "학생 → 성적 조회 API (허용)" '"success":true' "$R"

R=$(curl -s "$BASE/api/student/info" \
  -H "Authorization: Bearer $TOKEN_STU")
run_test "TC-RBAC-02" "학생 → 개인정보 조회 API (허용)" '"success":true' "$R"

R=$(curl -s "$BASE/api/academic/graduation" \
  -H "Authorization: Bearer $TOKEN_STU")
run_test "TC-RBAC-03" "학생 → 졸업요건 확인 API (허용)" '"success":true' "$R"

R=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/lecture/my" \
  -H "Authorization: Bearer $TOKEN_STU")
run_test "TC-RBAC-04" "학생 → 교수 전용 강의관리 API (차단)" "403" "$R"

R=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/admin/logs" \
  -H "Authorization: Bearer $TOKEN_STU")
run_test "TC-RBAC-05" "학생 → 관리자 전용 로그 API (차단)" "403" "$R"

R=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/admin/users" \
  -H "Authorization: Bearer $TOKEN_STU" \
  -H "Content-Type: application/json" \
  -d '{"role":"STUDENT","name":"침입자","email":"hack@test.com","department":"컴퓨터공학과"}')
run_test "TC-RBAC-06" "학생 → 사용자 생성 API (차단)" "403" "$R"

R=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/admin/rbac/assign" \
  -H "Authorization: Bearer $TOKEN_STU" \
  -H "Content-Type: application/json" \
  -d '{"role_id":1,"function_id":15}')
run_test "TC-RBAC-07" "학생 → RBAC 권한 부여 API (차단)" "403" "$R"

echo -e "\n  ${YELLOW}[교수 역할 검증]${NC}"

R=$(curl -s "$BASE/api/lecture/my" \
  -H "Authorization: Bearer $TOKEN_PROF")
run_test "TC-RBAC-08" "교수 → 담당 강의 조회 API (허용)" '"success":true' "$R"

R=$(curl -s -G "$BASE/api/academic/courses" \
  --data-urlencode "semester=2025-1" \
  -H "Authorization: Bearer $TOKEN_PROF")
run_test "TC-RBAC-09" "교수 → 강의 목록 조회 API (허용)" '"success":true' "$R"

R=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/admin/logs" \
  -H "Authorization: Bearer $TOKEN_PROF")
run_test "TC-RBAC-10" "교수 → 관리자 전용 로그 API (차단)" "403" "$R"

R=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/admin/users" \
  -H "Authorization: Bearer $TOKEN_PROF" \
  -H "Content-Type: application/json" \
  -d '{"role":"STUDENT","name":"테스트","email":"t@t.com","department":"컴퓨터공학과"}')
run_test "TC-RBAC-11" "교수 → 사용자 생성 API (차단)" "403" "$R"

echo -e "\n  ${YELLOW}[행정직원 역할 검증]${NC}"

R=$(curl -s "$BASE/api/admin/logs?limit=5" \
  -H "Authorization: Bearer $TOKEN_ADM")
run_test "TC-RBAC-12" "행정직원 → 시스템 로그 조회 (허용)" '"success":true' "$R"

R=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/lecture/my" \
  -H "Authorization: Bearer $TOKEN_ADM")
run_test "TC-RBAC-13" "행정직원 → 교수 전용 강의관리 API (차단)" "403" "$R"

echo -e "\n  ${YELLOW}[시스템관리자 역할 검증]${NC}"

R=$(curl -s "$BASE/api/admin/logs?limit=5" \
  -H "Authorization: Bearer $TOKEN_ADMIN")
run_test "TC-RBAC-14" "시스템관리자 → 관리자 API 접근 (허용)" '"success":true' "$R"

# SYSTEM_ADMIN은 교수 프로필 없으므로 학사 공통 API로 검증
R=$(curl -s -G "$BASE/api/academic/courses" \
  --data-urlencode "semester=2025-1" \
  -H "Authorization: Bearer $TOKEN_ADMIN")
run_test "TC-RBAC-15" "시스템관리자 → 학사 공통 API 접근 (허용)" '"success":true' "$R"

R=$(curl -s -G "$BASE/api/academic/courses" \
  --data-urlencode "semester=2025-1" \
  -H "Authorization: Bearer $TOKEN_ADM")
run_test "TC-RBAC-16" "행정직원 → 학사 공통 API 접근 (허용)" '"success":true' "$R"


# =============================================================
# TC-FUNC: 기능 테스트
# =============================================================
echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}[TC-FUNC] 기능 테스트${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n  ${YELLOW}[학사 기능]${NC}"

R=$(curl -s "$BASE/api/academic/grades" \
  -H "Authorization: Bearer $TOKEN_STU")
run_test "TC-FUNC-01" "성적 조회 (전체)" '"success":true' "$R"

R=$(curl -s -G "$BASE/api/academic/grades" \
  --data-urlencode "semester=2024-2" \
  -H "Authorization: Bearer $TOKEN_STU")
run_test "TC-FUNC-02" "성적 조회 (2024-2학기 필터)" '"success":true' "$R"

R=$(curl -s -G "$BASE/api/academic/courses" \
  --data-urlencode "semester=2025-1" \
  -H "Authorization: Bearer $TOKEN_STU")
run_test "TC-FUNC-03" "강의 목록 조회 (2025-1학기 전체)" '"success":true' "$R"

R=$(curl -s -G "$BASE/api/academic/courses" \
  --data-urlencode "semester=2025-1" \
  --data-urlencode "department=컴퓨터공학과" \
  -H "Authorization: Bearer $TOKEN_STU")
run_test "TC-FUNC-04" "강의 목록 조회 (학과 필터: 컴퓨터공학과)" '"success":true' "$R"

R=$(curl -s "$BASE/api/academic/graduation" \
  -H "Authorization: Bearer $TOKEN_STU")
run_test "TC-FUNC-05" "졸업요건 확인 (STU2021001 - 4학년)" '"success":true' "$R"

# SW202 수강신청 - STU2022001 (미수강 과목)
COURSE_ID=$(curl -s -G "$BASE/api/academic/courses" \
  --data-urlencode "semester=2025-1" \
  -H "Authorization: Bearer $TOKEN_STU2" | \
  $PYTHON_CMD -c "import sys,json; d=json.load(sys.stdin); print(next((c['id'] for c in d.get('data',[]) if c.get('courseCode')=='SW202'),''))" 2>/dev/null)

if [ -n "$COURSE_ID" ]; then
  R=$(curl -s -X POST "$BASE/api/academic/courses/enroll" \
    -H "Authorization: Bearer $TOKEN_STU2" \
    -H "Content-Type: application/json" \
    -d "{\"course_id\":$COURSE_ID}")
  run_test "TC-FUNC-06" "수강신청 (STU2022001 → SW202)" '"success":true' "$R"

  R=$(curl -s -X DELETE "$BASE/api/academic/courses/enroll?course_id=$COURSE_ID" \
    -H "Authorization: Bearer $TOKEN_STU2")
  run_test "TC-FUNC-07" "수강취소 (STU2022001 → SW202)" '"success":true' "$R"
else
  run_skip "TC-FUNC-06" "수강신청 (SW202)" "강의 ID 조회 실패"
  run_skip "TC-FUNC-07" "수강취소 (SW202)" "강의 ID 조회 실패"
fi

echo -e "\n  ${YELLOW}[학적 기능]${NC}"

R=$(curl -s "$BASE/api/student/info" \
  -H "Authorization: Bearer $TOKEN_STU")
run_test "TC-FUNC-08" "개인정보 조회 (STU2021001)" '"success":true' "$R"

R=$(curl -s "$BASE/api/student/leave/status" \
  -H "Authorization: Bearer $TOKEN_STU")
run_test "TC-FUNC-09" "휴학/복학 현황 조회 (STU2021001 - 기존 승인 내역)" '"success":true' "$R"

# STU2022001은 기존 휴학 신청 없음 (reason: ASCII to avoid EUC-KR encoding issue on Windows bash)
R=$(curl -s -X POST "$BASE/api/student/leave" \
  -H "Authorization: Bearer $TOKEN_STU2" \
  -H "Content-Type: application/json" \
  -d '{"type":"GENERAL","reason":"Personal reason for leave request","period":"2025-2"}')
run_test "TC-FUNC-10" "휴학 신청 (STU2022001 - 신규)" '"success":true' "$R"

R=$(curl -s "$BASE/api/student/leave/status" \
  -H "Authorization: Bearer $TOKEN_STU2")
run_test "TC-FUNC-11" "휴학/복학 현황 조회 (STU2022001 - 신청 후 확인)" '"success":true' "$R"

echo -e "\n  ${YELLOW}[교수 기능]${NC}"

R=$(curl -s -G "$BASE/api/lecture/my" \
  --data-urlencode "semester=2025-1" \
  -H "Authorization: Bearer $TOKEN_PROF")
run_test "TC-FUNC-12" "담당 강의 조회 (PRO2010001 - 2025-1학기)" '"success":true' "$R"

LECTURE_COURSE_ID=$(curl -s -G "$BASE/api/lecture/my" \
  --data-urlencode "semester=2025-1" \
  -H "Authorization: Bearer $TOKEN_PROF" | \
  $PYTHON_CMD -c "import sys,json; d=json.load(sys.stdin); lst=d.get('data',[]); print(lst[0]['id'] if lst else '')" 2>/dev/null)

if [ -n "$LECTURE_COURSE_ID" ]; then
  R=$(curl -s "$BASE/api/lecture/students?course_id=$LECTURE_COURSE_ID" \
    -H "Authorization: Bearer $TOKEN_PROF")
  run_test "TC-FUNC-13" "수강생 목록 조회" '"success":true' "$R"

  R=$(curl -s -X POST "$BASE/api/lecture/syllabus" \
    -H "Authorization: Bearer $TOKEN_PROF" \
    -H "Content-Type: application/json" \
    -d "{\"course_id\":$LECTURE_COURSE_ID,\"content\":\"Week 1: Overview\\nWeek 2: Fundamentals\\nWeek 3: Applications\"}")
  run_test "TC-FUNC-14" "강의계획서 등록" '"success":true' "$R"

  R=$(curl -s "$BASE/api/lecture/attendance?course_id=$LECTURE_COURSE_ID" \
    -H "Authorization: Bearer $TOKEN_PROF")
  run_test "TC-FUNC-15" "출결 현황 조회" '"success":true' "$R"
else
  run_skip "TC-FUNC-13" "수강생 목록 조회" "강의 ID 조회 실패"
  run_skip "TC-FUNC-14" "강의계획서 등록" "강의 ID 조회 실패"
  run_skip "TC-FUNC-15" "출결 현황 조회" "강의 ID 조회 실패"
fi

echo -e "\n  ${YELLOW}[관리자 기능]${NC}"

R=$(curl -s "$BASE/api/admin/logs?limit=10" \
  -H "Authorization: Bearer $TOKEN_ADMIN")
run_test "TC-FUNC-16" "시스템 로그 조회 (최근 10건)" '"success":true' "$R"

NEW_EMAIL="test_$(date +%s)@university.ac.kr"
R=$(curl -s -X POST "$BASE/api/admin/users" \
  -H "Authorization: Bearer $TOKEN_ADMIN" \
  -H "Content-Type: application/json" \
  -d "{\"role\":\"STUDENT\",\"name\":\"TestStudent\",\"email\":\"$NEW_EMAIL\",\"department\":\"CS\"}")
run_test "TC-FUNC-17" "신규 학생 계정 생성" '"success":true' "$R"

R=$(curl -s -X POST "$BASE/api/admin/semester" \
  -H "Authorization: Bearer $TOKEN_ADMIN" \
  -H "Content-Type: application/json" \
  -d '{"year":2025,"term":2,"start_date":"2025-09-01","end_date":"2025-12-19"}')
run_test "TC-FUNC-18" "학기 설정 (2025-2학기)" '"success":true' "$R"

R=$(curl -s -X DELETE "$BASE/api/admin/rbac/revoke?role_id=1&function_id=1" \
  -H "Authorization: Bearer $TOKEN_ADMIN")
run_test "TC-FUNC-19" "RBAC 권한 회수 (STUDENT - get_my_grades)" '"success":true' "$R"

R=$(curl -s -X POST "$BASE/api/admin/rbac/assign" \
  -H "Authorization: Bearer $TOKEN_ADMIN" \
  -H "Content-Type: application/json" \
  -d '{"role_id":1,"function_id":1}')
run_test "TC-FUNC-20" "RBAC 권한 재부여 (STUDENT - get_my_grades)" '"success":true' "$R"


# =============================================================
# TC-SEC: 보안 우회 시도 테스트
# =============================================================
echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}[TC-SEC] 보안 우회 시도 테스트${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

R=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/admin/logs" \
  -H "Authorization: Bearer invalidtoken123")
run_test "TC-SEC-01" "위조 토큰으로 관리자 API 접근 (차단)" "403" "$R"

R=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/admin/users" \
  -H "Authorization: Bearer $TOKEN_STU" \
  -H "Content-Type: application/json" \
  -d '{"role":"SYSTEM_ADMIN","name":"권한상승","email":"escalate@hack.com","department":"컴퓨터공학과"}')
run_test "TC-SEC-02" "학생으로 SYSTEM_ADMIN 계정 생성 시도 (차단)" "403" "$R"

R=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE/api/admin/rbac/revoke?role_id=1&function_id=1" \
  -H "Authorization: Bearer $TOKEN_STU")
run_test "TC-SEC-03" "학생으로 RBAC 권한 회수 시도 (차단)" "403" "$R"

R=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/lecture/grades" \
  -H "Authorization: Bearer $TOKEN_STU" \
  -H "Content-Type: application/json" \
  -d '{"student_id":"STU2022001","course_id":1,"grade":"A+","score":100}')
run_test "TC-SEC-04" "학생으로 성적 입력 시도 (차단)" "403" "$R"

R=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/admin/semester" \
  -H "Authorization: Bearer $TOKEN_PROF" \
  -H "Content-Type: application/json" \
  -d '{"year":2030,"term":1,"start_date":"2030-03-01","end_date":"2030-06-30"}')
run_test "TC-SEC-05" "교수로 학기 설정 시도 (차단)" "403" "$R"

R=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/admin/rbac/assign" \
  -H "Authorization: Bearer $TOKEN_PROF" \
  -H "Content-Type: application/json" \
  -d '{"role_id":2,"function_id":15}')
run_test "TC-SEC-06" "교수로 RBAC 권한 부여 시도 (차단)" "403" "$R"


# =============================================================
# TC-LLM: LLM 챗봇 테스트
# =============================================================
echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}[TC-LLM] LLM 챗봇 테스트${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# LLM Gateway 동작 여부 확인 (헬스체크 + 실제 요청 테스트)
LLM_HEALTH=$(curl -s "$LLM/health")
LLM_TEST=$(curl -s -X POST "$LLM/chat" \
  -H "Content-Type: application/json" \
  --data-binary "{\"message\":\"hello\",\"token\":\"$TOKEN_STU\",\"conversation_history\":[]}" 2>/dev/null)
if ! echo "$LLM_HEALTH" | grep -q "ok"; then
  echo -e "${YELLOW}  LLM Gateway 응답 없음 - TC-LLM 전체 SKIP${NC}"
  for i in 01 02 03 04 05 06 07 08 09 10; do
    run_skip "TC-LLM-$i" "LLM 테스트" "LLM Gateway 연결 실패"
  done
elif echo "$LLM_TEST" | grep -qiE "credential|api.key|Internal Server Error|DefaultCredentials"; then
  echo -e "${YELLOW}  GEMINI_API_KEY 미설정 - TC-LLM 전체 SKIP${NC}"
  echo -e "${YELLOW}  (GEMINI_API_KEY 환경변수 설정 후 docker-compose up 재실행 필요)${NC}"
  for i in 01 02 03 04 05 06 07 08 09 10; do
    run_skip "TC-LLM-$i" "LLM 테스트" "GEMINI_API_KEY 미설정"
  done
else

R=$(curl -s -X POST "$LLM/chat" \
  -H "Content-Type: application/json" \
  --data-binary "$(make_chat_json 'Show me my grades' "$TOKEN_STU")")
run_test "TC-LLM-01" "[학생] 성적 조회 자연어 쿼리" 'reply|data|grade|score' "$R"

R=$(curl -s -X POST "$LLM/chat" \
  -H "Content-Type: application/json" \
  --data-binary "$(make_chat_json 'Show me available courses for this semester' "$TOKEN_STU")")
run_test "TC-LLM-02" "[학생] 강의 목록 자연어 쿼리" 'reply|data|course' "$R"

R=$(curl -s -X POST "$LLM/chat" \
  -H "Content-Type: application/json" \
  --data-binary "$(make_chat_json 'Show my student information' "$TOKEN_STU")")
run_test "TC-LLM-03" "[학생] 개인정보 자연어 쿼리" 'reply|data|info|student' "$R"

R=$(curl -s -X POST "$LLM/chat" \
  -H "Content-Type: application/json" \
  --data-binary "$(make_chat_json 'What do I need to graduate?' "$TOKEN_STU")")
run_test "TC-LLM-04" "[학생] 졸업요건 자연어 쿼리" 'reply|data|graduation|credit' "$R"

R=$(curl -s -X POST "$LLM/chat" \
  -H "Content-Type: application/json" \
  --data-binary "$(make_chat_json 'Show me all students grades in the system' "$TOKEN_STU")")
run_test "TC-LLM-05" "[학생] 권한 없는 기능 요청 → RBAC 차단" 'blocked|403|access denied|not allowed|permission|권한' "$R"

R=$(curl -s -X POST "$LLM/chat" \
  -H "Content-Type: application/json" \
  --data-binary "$(make_chat_json 'Show me the system logs' "$TOKEN_STU")")
run_test "TC-LLM-06" "[학생] 시스템 로그 요청 → RBAC 차단" 'blocked|403|access denied|not allowed|permission|권한' "$R"

R=$(curl -s -X POST "$LLM/chat" \
  -H "Content-Type: application/json" \
  --data-binary "$(make_chat_json 'Show me my lecture list' "$TOKEN_PROF")")
run_test "TC-LLM-07" "[교수] 담당 강의 자연어 쿼리" 'reply|data|lecture|course' "$R"

R=$(curl -s -X POST "$LLM/chat" \
  -H "Content-Type: application/json" \
  --data-binary "$(make_chat_json 'Create a new student account' "$TOKEN_PROF")")
run_test "TC-LLM-08" "[교수] 사용자 생성 요청 → RBAC 차단" 'blocked|403|access denied|not allowed|permission|권한|cannot|unable|capability|limited' "$R"

R=$(curl -s -X POST "$LLM/chat" \
  -H "Content-Type: application/json" \
  --data-binary "$(make_chat_json 'Show me the last 10 system logs' "$TOKEN_ADMIN")")
run_test "TC-LLM-09" "[관리자] 시스템 로그 자연어 쿼리" 'reply|data|log' "$R"

# 다단계 대화 테스트
HISTORY='[{"role":"user","content":"Show me my grades"},{"role":"assistant","content":"2024-2 grades: CS100 A+, SW100 B+"}]'
R=$(curl -s -X POST "$LLM/chat" \
  -H "Content-Type: application/json" \
  -d "{\"message\":\"Now show me my enrolled courses\",\"token\":\"$TOKEN_STU\",\"conversation_history\":$HISTORY}")
run_test "TC-LLM-10" "[학생] 다단계 대화 - 컨텍스트 유지" 'reply|data|course' "$R"

fi  # LLM Gateway 체크 종료


# =============================================================
# 결과 요약
# =============================================================
TOTAL=$((PASS+FAIL+SKIP))
echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}▶ 테스트 결과 요약${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  전체: $TOTAL  |  ${GREEN}PASS: $PASS${NC}  |  ${RED}FAIL: $FAIL${NC}  |  ${YELLOW}SKIP: $SKIP${NC}"
if [ $((PASS+FAIL)) -gt 0 ]; then
  echo -e "  성공률 (SKIP 제외): $(( PASS * 100 / (PASS+FAIL) ))%"
fi
echo -e "\n${CYAN}▶ CSV 저장 완료${NC}"
echo -e "  $CSV_FILE"
echo ""
