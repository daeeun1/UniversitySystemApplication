-- ============================================================
-- University Information System - Database Schema
-- ============================================================

SET NAMES utf8mb4;
SET time_zone = '+09:00';

-- ============================================================
-- RBAC: 역할 / 함수 / 역할-함수 매핑
-- ============================================================

CREATE TABLE roles (
    id          INT          AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(50)  NOT NULL UNIQUE COMMENT '역할명 (STUDENT/PROFESSOR/ADMIN/SYSTEM_ADMIN)',
    description VARCHAR(255),
    created_at  DATETIME     DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE functions (
    id          INT          AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE COMMENT 'Function Calling 함수명',
    description VARCHAR(255) COMMENT '함수 설명',
    api_path    VARCHAR(255) COMMENT '매핑된 백엔드 API 경로',
    http_method VARCHAR(10)  COMMENT 'GET/POST/DELETE',
    created_at  DATETIME     DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE role_functions (
    role_id     INT NOT NULL,
    function_id INT NOT NULL,
    granted_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (role_id, function_id),
    FOREIGN KEY (role_id)     REFERENCES roles(id)     ON DELETE CASCADE,
    FOREIGN KEY (function_id) REFERENCES functions(id) ON DELETE CASCADE
);

-- ============================================================
-- 학과 / 학기
-- ============================================================

CREATE TABLE departments (
    id         INT          AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(100) NOT NULL UNIQUE COMMENT '학과명',
    college    VARCHAR(100) COMMENT '단과대학',
    created_at DATETIME     DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE semesters (
    id             INT  AUTO_INCREMENT PRIMARY KEY,
    year           INT  NOT NULL COMMENT '연도',
    term           INT  NOT NULL COMMENT '학기 (1 또는 2)',
    start_date     DATE NOT NULL,
    end_date       DATE NOT NULL,
    enroll_start   DATE COMMENT '수강신청 시작일',
    enroll_end     DATE COMMENT '수강신청 종료일',
    is_current     BOOLEAN DEFAULT FALSE COMMENT '현재 학기 여부',
    UNIQUE KEY uq_semester (year, term)
);

-- ============================================================
-- 사용자 (공통)
-- ============================================================

CREATE TABLE users (
    id             BIGINT       AUTO_INCREMENT PRIMARY KEY,
    user_number    VARCHAR(20)  NOT NULL UNIQUE COMMENT '학번 또는 교번',
    password_hash  VARCHAR(255) NOT NULL,
    name           VARCHAR(50)  NOT NULL,
    email          VARCHAR(100) NOT NULL UNIQUE,
    phone          VARCHAR(20),
    role_id        INT          NOT NULL,
    is_active      BOOLEAN      DEFAULT TRUE,
    created_at     DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(id)
);

-- ============================================================
-- 학생
-- ============================================================

CREATE TABLE students (
    user_id          BIGINT      PRIMARY KEY,
    admission_year   INT         NOT NULL COMMENT '입학연도',
    grade            INT         NOT NULL DEFAULT 1 COMMENT '학년',
    status           ENUM('ENROLLED','ON_LEAVE','GRADUATED','EXPELLED') NOT NULL DEFAULT 'ENROLLED' COMMENT '학적 상태',
    total_credits    INT         DEFAULT 0 COMMENT '취득 학점',
    main_dept_id     INT         NOT NULL COMMENT '주전공 학과',
    FOREIGN KEY (user_id)      REFERENCES users(id)       ON DELETE CASCADE,
    FOREIGN KEY (main_dept_id) REFERENCES departments(id)
);

CREATE TABLE student_majors (
    id             INT    AUTO_INCREMENT PRIMARY KEY,
    student_id     BIGINT NOT NULL COMMENT '학생 user_id',
    department_id  INT    NOT NULL COMMENT '학과 ID',
    major_type     ENUM('MAIN','DOUBLE','MINOR') NOT NULL COMMENT '주전공/복수전공/부전공',
    declared_at    DATE,
    UNIQUE KEY uq_student_major (student_id, department_id, major_type),
    FOREIGN KEY (student_id)    REFERENCES students(user_id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES departments(id)
);

-- ============================================================
-- 교수
-- ============================================================

CREATE TABLE professors (
    user_id      BIGINT      PRIMARY KEY,
    department_id INT        NOT NULL,
    `rank`         ENUM('ASSISTANT','ASSOCIATE','FULL','EMERITUS') NOT NULL DEFAULT 'ASSISTANT' COMMENT '직급',
    office       VARCHAR(100) COMMENT '연구실',
    FOREIGN KEY (user_id)       REFERENCES users(id)       ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES departments(id)
);

-- ============================================================
-- 강의
-- ============================================================

CREATE TABLE courses (
    id            INT          AUTO_INCREMENT PRIMARY KEY,
    course_code   VARCHAR(20)  NOT NULL COMMENT '강의 코드',
    name          VARCHAR(150) NOT NULL COMMENT '강의명',
    credits       INT          NOT NULL COMMENT '학점',
    department_id INT          NOT NULL COMMENT '개설 학과',
    professor_id  BIGINT       NOT NULL COMMENT '담당 교수 user_id',
    semester_id   INT          NOT NULL,
    max_students  INT          DEFAULT 40 COMMENT '수강 정원',
    classroom     VARCHAR(100) COMMENT '강의실',
    schedule      VARCHAR(100) COMMENT '요일/시간 (예: 월수 10:30-12:00)',
    syllabus      TEXT         COMMENT '강의계획서',
    created_at    DATETIME     DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_course_semester (course_code, semester_id),
    FOREIGN KEY (department_id) REFERENCES departments(id),
    FOREIGN KEY (professor_id)  REFERENCES professors(user_id),
    FOREIGN KEY (semester_id)   REFERENCES semesters(id)
);

-- ============================================================
-- 수강신청 / 성적
-- ============================================================

CREATE TABLE enrollments (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_id   BIGINT NOT NULL COMMENT '학생 user_id',
    course_id    INT    NOT NULL,
    enrolled_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    status       ENUM('ENROLLED','DROPPED','COMPLETED') NOT NULL DEFAULT 'ENROLLED',
    UNIQUE KEY uq_enrollment (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(user_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id)  REFERENCES courses(id)       ON DELETE CASCADE
);

CREATE TABLE grades (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    enrollment_id BIGINT  NOT NULL UNIQUE,
    score        DECIMAL(5,2) COMMENT '점수 (0.00 ~ 100.00)',
    grade        VARCHAR(10) COMMENT '등급 (Java enum name: A_PLUS/A_ZERO/B_PLUS/...)',
    graded_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (enrollment_id) REFERENCES enrollments(id) ON DELETE CASCADE
);

-- ============================================================
-- 출결
-- ============================================================

CREATE TABLE attendances (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    enrollment_id BIGINT NOT NULL,
    class_date   DATE   NOT NULL COMMENT '수업일',
    status       ENUM('PRESENT','ABSENT','LATE','EXCUSED') NOT NULL DEFAULT 'PRESENT',
    note         VARCHAR(255),
    UNIQUE KEY uq_attendance (enrollment_id, class_date),
    FOREIGN KEY (enrollment_id) REFERENCES enrollments(id) ON DELETE CASCADE
);

-- ============================================================
-- 학적 변동 (휴학/복학)
-- ============================================================

CREATE TABLE leave_requests (
    id             INT    AUTO_INCREMENT PRIMARY KEY,
    student_id     BIGINT NOT NULL COMMENT '학생 user_id',
    type           ENUM('GENERAL','MILITARY','MEDICAL','OTHER') NOT NULL COMMENT '휴학 유형',
    reason         TEXT   NOT NULL COMMENT '사유',
    target_semester_id INT COMMENT '휴학/복학 대상 학기',
    request_type   ENUM('LEAVE','REINSTATEMENT') NOT NULL COMMENT '신청 유형',
    status         ENUM('PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'PENDING',
    reviewed_by    BIGINT COMMENT '처리자 user_id',
    reviewed_at    DATETIME,
    created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id)         REFERENCES students(user_id),
    FOREIGN KEY (target_semester_id) REFERENCES semesters(id),
    FOREIGN KEY (reviewed_by)        REFERENCES users(id)
);

-- ============================================================
-- 시스템 로그
-- ============================================================

CREATE TABLE system_logs (
    id              BIGINT   AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT   COMMENT '요청 사용자',
    function_name   VARCHAR(100) COMMENT '호출된 Function',
    api_path        VARCHAR(255),
    http_method     VARCHAR(10),
    request_body    JSON,
    response_status INT,
    rbac_layer      ENUM('LLM','API','BOTH') COMMENT 'RBAC 검증 레이어',
    is_blocked      BOOLEAN  DEFAULT FALSE COMMENT 'RBAC 차단 여부',
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_logs_user    (user_id),
    INDEX idx_logs_created (created_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- ============================================================
-- 기본 데이터 삽입
-- ============================================================

-- 역할
INSERT INTO roles (name, description) VALUES
('STUDENT',      '학생 - 수강신청, 성적 조회, 학적 신청'),
('PROFESSOR',    '교수 - 강의 관리, 성적 입력'),
('ADMIN',        '행정직원 - 학적 관리, 수강 승인'),
('SYSTEM_ADMIN', '시스템 관리자 - 전체 권한');

-- 함수 목록 (20개)
INSERT INTO functions (name, description, api_path, http_method) VALUES
('get_my_grades',                '성적 조회',           '/api/academic/grades',        'GET'),
('get_course_list',              '수강 가능 강의 조회', '/api/academic/courses',        'GET'),
('apply_for_course',             '수강신청',             '/api/academic/courses/enroll', 'POST'),
('drop_course',                  '수강취소',             '/api/academic/courses/enroll', 'DELETE'),
('check_graduation_requirements','졸업요건 확인',        '/api/academic/graduation',     'GET'),
('get_my_info',                  '개인정보 조회',        '/api/student/info',            'GET'),
('apply_for_leave',              '휴학신청',             '/api/student/leave',           'POST'),
('apply_for_reinstatement',      '복학신청',             '/api/student/reinstatement',   'POST'),
('get_leave_status',             '휴학/복학 현황 조회', '/api/student/leave/status',     'GET'),
('get_my_lectures',              '담당 강의 조회',       '/api/lecture/my',              'GET'),
('input_grade',                  '성적 입력',            '/api/lecture/grades',          'POST'),
('get_student_list',             '수강생 목록 조회',     '/api/lecture/students',        'GET'),
('upload_syllabus',              '강의계획서 등록',      '/api/lecture/syllabus',        'POST'),
('get_attendance',               '출결 현황 조회',       '/api/lecture/attendance',      'GET'),
('create_user',                  '사용자 생성',          '/api/admin/users',             'POST'),
('assign_role_function',         '역할 권한 부여',       '/api/admin/rbac/assign',       'POST'),
('revoke_role_function',         '역할 권한 회수',       '/api/admin/rbac/revoke',       'DELETE'),
('set_semester',                 '학기 설정',            '/api/admin/semester',          'POST'),
('get_system_logs',              '시스템 로그 조회',     '/api/admin/logs',              'GET'),
('approve_leave_request',        '휴학/복학 승인',       '/api/admin/leave/approve',     'POST');

-- 역할별 함수 권한 매핑
-- STUDENT
INSERT INTO role_functions (role_id, function_id)
SELECT r.id, f.id FROM roles r, functions f
WHERE r.name = 'STUDENT'
  AND f.name IN ('get_my_grades','get_course_list','apply_for_course','drop_course',
                 'check_graduation_requirements','get_my_info','apply_for_leave',
                 'apply_for_reinstatement','get_leave_status');

-- PROFESSOR
INSERT INTO role_functions (role_id, function_id)
SELECT r.id, f.id FROM roles r, functions f
WHERE r.name = 'PROFESSOR'
  AND f.name IN ('get_my_info','get_course_list','get_my_lectures','input_grade',
                 'get_student_list','upload_syllabus','get_attendance');

-- ADMIN
INSERT INTO role_functions (role_id, function_id)
SELECT r.id, f.id FROM roles r, functions f
WHERE r.name = 'ADMIN'
  AND f.name IN ('get_my_info','get_course_list','get_student_list','get_leave_status',
                 'approve_leave_request','create_user','set_semester');

-- SYSTEM_ADMIN (전체 권한)
INSERT INTO role_functions (role_id, function_id)
SELECT r.id, f.id FROM roles r, functions f
WHERE r.name = 'SYSTEM_ADMIN';

-- 학과
INSERT INTO departments (name, college) VALUES
('컴퓨터공학과',   '공과대학'),
('소프트웨어학과', '공과대학'),
('전기전자공학과', '공과대학'),
('경영학과',       '경영대학'),
('영어영문학과',   '인문대학');

-- 학기
INSERT INTO semesters (year, term, start_date, end_date, enroll_start, enroll_end, is_current) VALUES
(2024, 1, '2024-03-04', '2024-06-21', '2024-02-19', '2024-02-23', FALSE),
(2024, 2, '2024-09-02', '2024-12-20', '2024-08-19', '2024-08-23', FALSE),
(2025, 1, '2025-03-03', '2025-06-20', '2025-02-17', '2025-02-21', TRUE);

-- ============================================================
-- 계정 (공통 비밀번호: Test1234!, 관리자: Admin1234!)
-- ============================================================

-- 시스템 관리자
INSERT INTO users (user_number, password_hash, name, email, role_id) VALUES
('ADMIN001', '$2b$12$lg0NK2CtL0qiAcV6CzF7V.KCcZmkf5tZ3jZPzqrJESaucU71G674O', '시스템관리자', 'admin@university.ac.kr', (SELECT id FROM roles WHERE name = 'SYSTEM_ADMIN'));

-- 행정직원
INSERT INTO users (user_number, password_hash, name, email, role_id) VALUES
('ADM001', '$2b$12$5C/WtQY.5Cv85SoX0/hZiOoFvpsWTXxQYF4722HZZDxG.IG20r3Ha', '김행정', 'adm001@university.ac.kr', (SELECT id FROM roles WHERE name = 'ADMIN'));

-- 교수
INSERT INTO users (user_number, password_hash, name, email, role_id) VALUES
('PRO2010001', '$2b$12$5C/WtQY.5Cv85SoX0/hZiOoFvpsWTXxQYF4722HZZDxG.IG20r3Ha', '이교수', 'pro001@university.ac.kr', (SELECT id FROM roles WHERE name = 'PROFESSOR')),
('PRO2015001', '$2b$12$5C/WtQY.5Cv85SoX0/hZiOoFvpsWTXxQYF4722HZZDxG.IG20r3Ha', '박교수', 'pro002@university.ac.kr', (SELECT id FROM roles WHERE name = 'PROFESSOR'));

INSERT INTO professors (user_id, department_id, `rank`, office) VALUES
((SELECT id FROM users WHERE user_number = 'PRO2010001'), (SELECT id FROM departments WHERE name = '컴퓨터공학과'), 'FULL', '공학관 301호'),
((SELECT id FROM users WHERE user_number = 'PRO2015001'), (SELECT id FROM departments WHERE name = '소프트웨어학과'), 'ASSOCIATE', '공학관 205호');

-- 학생
INSERT INTO users (user_number, password_hash, name, email, role_id) VALUES
('STU2021001', '$2b$12$5C/WtQY.5Cv85SoX0/hZiOoFvpsWTXxQYF4722HZZDxG.IG20r3Ha', '홍길동', 'stu001@university.ac.kr', (SELECT id FROM roles WHERE name = 'STUDENT')),
('STU2022001', '$2b$12$5C/WtQY.5Cv85SoX0/hZiOoFvpsWTXxQYF4722HZZDxG.IG20r3Ha', '김철수', 'stu002@university.ac.kr', (SELECT id FROM roles WHERE name = 'STUDENT')),
('STU2023001', '$2b$12$5C/WtQY.5Cv85SoX0/hZiOoFvpsWTXxQYF4722HZZDxG.IG20r3Ha', '이영희', 'stu003@university.ac.kr', (SELECT id FROM roles WHERE name = 'STUDENT'));

INSERT INTO students (user_id, admission_year, grade, status, total_credits, main_dept_id) VALUES
((SELECT id FROM users WHERE user_number = 'STU2021001'), 2021, 4, 'ENROLLED', 108, (SELECT id FROM departments WHERE name = '컴퓨터공학과')),
((SELECT id FROM users WHERE user_number = 'STU2022001'), 2022, 3, 'ENROLLED', 72,  (SELECT id FROM departments WHERE name = '소프트웨어학과')),
((SELECT id FROM users WHERE user_number = 'STU2023001'), 2023, 2, 'ENROLLED', 36,  (SELECT id FROM departments WHERE name = '경영학과'));

-- 학생 전공
INSERT INTO student_majors (student_id, department_id, major_type, declared_at) VALUES
((SELECT id FROM users WHERE user_number = 'STU2021001'), (SELECT id FROM departments WHERE name = '컴퓨터공학과'), 'MAIN', '2021-03-02'),
((SELECT id FROM users WHERE user_number = 'STU2022001'), (SELECT id FROM departments WHERE name = '소프트웨어학과'), 'MAIN', '2022-03-02'),
((SELECT id FROM users WHERE user_number = 'STU2023001'), (SELECT id FROM departments WHERE name = '경영학과'), 'MAIN', '2023-03-06');

-- ============================================================
-- 강의 데이터
-- ============================================================

-- 2024년 2학기 강의 (완료)
INSERT INTO courses (course_code, name, credits, department_id, professor_id, semester_id, max_students, classroom, schedule) VALUES
('CS100', '프로그래밍기초', 3, (SELECT id FROM departments WHERE name = '컴퓨터공학과'), (SELECT id FROM users WHERE user_number = 'PRO2010001'), (SELECT id FROM semesters WHERE year = 2024 AND term = 2), 40, '공학관 101호', '월수 09:00-10:30'),
('CS102', '이산수학',       3, (SELECT id FROM departments WHERE name = '컴퓨터공학과'), (SELECT id FROM users WHERE user_number = 'PRO2010001'), (SELECT id FROM semesters WHERE year = 2024 AND term = 2), 35, '공학관 102호', '화목 10:30-12:00'),
('SW100', '운영체제',       3, (SELECT id FROM departments WHERE name = '소프트웨어학과'), (SELECT id FROM users WHERE user_number = 'PRO2015001'), (SELECT id FROM semesters WHERE year = 2024 AND term = 2), 35, '공학관 201호', '월수 13:00-14:30');

-- 2025년 1학기 강의 (현재)
INSERT INTO courses (course_code, name, credits, department_id, professor_id, semester_id, max_students, classroom, schedule) VALUES
('CS101', '자료구조',       3, (SELECT id FROM departments WHERE name = '컴퓨터공학과'), (SELECT id FROM users WHERE user_number = 'PRO2010001'), (SELECT id FROM semesters WHERE year = 2025 AND term = 1), 40, '공학관 101호', '월수 09:00-10:30'),
('CS201', '알고리즘',       3, (SELECT id FROM departments WHERE name = '컴퓨터공학과'), (SELECT id FROM users WHERE user_number = 'PRO2010001'), (SELECT id FROM semesters WHERE year = 2025 AND term = 1), 35, '공학관 102호', '화목 13:00-14:30'),
('SW101', '소프트웨어공학', 3, (SELECT id FROM departments WHERE name = '소프트웨어학과'), (SELECT id FROM users WHERE user_number = 'PRO2015001'), (SELECT id FROM semesters WHERE year = 2025 AND term = 1), 40, '공학관 201호', '월수 13:00-14:30'),
('SW201', '데이터베이스',   3, (SELECT id FROM departments WHERE name = '소프트웨어학과'), (SELECT id FROM users WHERE user_number = 'PRO2015001'), (SELECT id FROM semesters WHERE year = 2025 AND term = 1), 35, '공학관 202호', '화목 09:00-10:30');

-- ============================================================
-- 수강신청 데이터
-- ============================================================

-- 2024년 2학기 수강 (완료)
INSERT INTO enrollments (student_id, course_id, status) VALUES
((SELECT id FROM users WHERE user_number = 'STU2021001'), (SELECT id FROM courses WHERE course_code = 'CS100' AND semester_id = (SELECT id FROM semesters WHERE year = 2024 AND term = 2)), 'COMPLETED'),
((SELECT id FROM users WHERE user_number = 'STU2021001'), (SELECT id FROM courses WHERE course_code = 'SW100' AND semester_id = (SELECT id FROM semesters WHERE year = 2024 AND term = 2)), 'COMPLETED'),
((SELECT id FROM users WHERE user_number = 'STU2022001'), (SELECT id FROM courses WHERE course_code = 'CS100' AND semester_id = (SELECT id FROM semesters WHERE year = 2024 AND term = 2)), 'COMPLETED'),
((SELECT id FROM users WHERE user_number = 'STU2022001'), (SELECT id FROM courses WHERE course_code = 'CS102' AND semester_id = (SELECT id FROM semesters WHERE year = 2024 AND term = 2)), 'COMPLETED'),
((SELECT id FROM users WHERE user_number = 'STU2023001'), (SELECT id FROM courses WHERE course_code = 'SW100' AND semester_id = (SELECT id FROM semesters WHERE year = 2024 AND term = 2)), 'COMPLETED');

-- 2025년 1학기 수강신청 (현재)
INSERT INTO enrollments (student_id, course_id, status) VALUES
((SELECT id FROM users WHERE user_number = 'STU2021001'), (SELECT id FROM courses WHERE course_code = 'CS101' AND semester_id = (SELECT id FROM semesters WHERE year = 2025 AND term = 1)), 'ENROLLED'),
((SELECT id FROM users WHERE user_number = 'STU2021001'), (SELECT id FROM courses WHERE course_code = 'CS201' AND semester_id = (SELECT id FROM semesters WHERE year = 2025 AND term = 1)), 'ENROLLED'),
((SELECT id FROM users WHERE user_number = 'STU2022001'), (SELECT id FROM courses WHERE course_code = 'SW101' AND semester_id = (SELECT id FROM semesters WHERE year = 2025 AND term = 1)), 'ENROLLED'),
((SELECT id FROM users WHERE user_number = 'STU2022001'), (SELECT id FROM courses WHERE course_code = 'SW201' AND semester_id = (SELECT id FROM semesters WHERE year = 2025 AND term = 1)), 'ENROLLED'),
((SELECT id FROM users WHERE user_number = 'STU2023001'), (SELECT id FROM courses WHERE course_code = 'CS101' AND semester_id = (SELECT id FROM semesters WHERE year = 2025 AND term = 1)), 'ENROLLED'),
((SELECT id FROM users WHERE user_number = 'STU2023001'), (SELECT id FROM courses WHERE course_code = 'SW101' AND semester_id = (SELECT id FROM semesters WHERE year = 2025 AND term = 1)), 'ENROLLED');

-- ============================================================
-- 성적 데이터 (완료된 수강에 대해)
-- ============================================================

INSERT INTO grades (enrollment_id, score, grade) VALUES
((SELECT e.id FROM enrollments e JOIN users u ON e.student_id = u.id JOIN courses c ON e.course_id = c.id WHERE u.user_number = 'STU2021001' AND c.course_code = 'CS100'), 95.00, 'A_PLUS'),
((SELECT e.id FROM enrollments e JOIN users u ON e.student_id = u.id JOIN courses c ON e.course_id = c.id WHERE u.user_number = 'STU2021001' AND c.course_code = 'SW100'), 82.00, 'B_PLUS'),
((SELECT e.id FROM enrollments e JOIN users u ON e.student_id = u.id JOIN courses c ON e.course_id = c.id WHERE u.user_number = 'STU2022001' AND c.course_code = 'CS100'), 90.00, 'A_ZERO'),
((SELECT e.id FROM enrollments e JOIN users u ON e.student_id = u.id JOIN courses c ON e.course_id = c.id WHERE u.user_number = 'STU2022001' AND c.course_code = 'CS102'), 78.00, 'C_PLUS'),
((SELECT e.id FROM enrollments e JOIN users u ON e.student_id = u.id JOIN courses c ON e.course_id = c.id WHERE u.user_number = 'STU2023001' AND c.course_code = 'SW100'), 88.00, 'B_PLUS');

-- ============================================================
-- 추가 교수 계정
-- ============================================================

INSERT INTO users (user_number, password_hash, name, email, role_id) VALUES
('PRO2008001', '$2b$12$5C/WtQY.5Cv85SoX0/hZiOoFvpsWTXxQYF4722HZZDxG.IG20r3Ha', '최전기', 'pro003@university.ac.kr', (SELECT id FROM roles WHERE name = 'PROFESSOR')),
('PRO2012001', '$2b$12$5C/WtQY.5Cv85SoX0/hZiOoFvpsWTXxQYF4722HZZDxG.IG20r3Ha', '정경영', 'pro004@university.ac.kr', (SELECT id FROM roles WHERE name = 'PROFESSOR'));

INSERT INTO professors (user_id, department_id, `rank`, office) VALUES
((SELECT id FROM users WHERE user_number = 'PRO2008001'), (SELECT id FROM departments WHERE name = '전기전자공학과'), 'FULL',      '공학관 401호'),
((SELECT id FROM users WHERE user_number = 'PRO2012001'), (SELECT id FROM departments WHERE name = '경영학과'),     'ASSOCIATE', '경영관 201호');

-- ============================================================
-- 추가 학생 계정
-- ============================================================

INSERT INTO users (user_number, password_hash, name, email, role_id) VALUES
('STU2020001', '$2b$12$5C/WtQY.5Cv85SoX0/hZiOoFvpsWTXxQYF4722HZZDxG.IG20r3Ha', '박민준', 'stu004@university.ac.kr', (SELECT id FROM roles WHERE name = 'STUDENT')),
('STU2021002', '$2b$12$5C/WtQY.5Cv85SoX0/hZiOoFvpsWTXxQYF4722HZZDxG.IG20r3Ha', '최지수', 'stu005@university.ac.kr', (SELECT id FROM roles WHERE name = 'STUDENT')),
('STU2022002', '$2b$12$5C/WtQY.5Cv85SoX0/hZiOoFvpsWTXxQYF4722HZZDxG.IG20r3Ha', '윤서연', 'stu006@university.ac.kr', (SELECT id FROM roles WHERE name = 'STUDENT')),
('STU2023002', '$2b$12$5C/WtQY.5Cv85SoX0/hZiOoFvpsWTXxQYF4722HZZDxG.IG20r3Ha', '장현우', 'stu007@university.ac.kr', (SELECT id FROM roles WHERE name = 'STUDENT')),
('STU2024001', '$2b$12$5C/WtQY.5Cv85SoX0/hZiOoFvpsWTXxQYF4722HZZDxG.IG20r3Ha', '한소희', 'stu008@university.ac.kr', (SELECT id FROM roles WHERE name = 'STUDENT'));

INSERT INTO students (user_id, admission_year, grade, status, total_credits, main_dept_id) VALUES
((SELECT id FROM users WHERE user_number = 'STU2020001'), 2020, 4, 'ENROLLED',  135, (SELECT id FROM departments WHERE name = '컴퓨터공학과')),
((SELECT id FROM users WHERE user_number = 'STU2021002'), 2021, 4, 'ENROLLED',  108, (SELECT id FROM departments WHERE name = '전기전자공학과')),
((SELECT id FROM users WHERE user_number = 'STU2022002'), 2022, 3, 'ENROLLED',   72, (SELECT id FROM departments WHERE name = '경영학과')),
((SELECT id FROM users WHERE user_number = 'STU2023002'), 2023, 2, 'ENROLLED',   36, (SELECT id FROM departments WHERE name = '컴퓨터공학과')),
((SELECT id FROM users WHERE user_number = 'STU2024001'), 2024, 1, 'ENROLLED',    0, (SELECT id FROM departments WHERE name = '소프트웨어학과'));

INSERT INTO student_majors (student_id, department_id, major_type, declared_at) VALUES
((SELECT id FROM users WHERE user_number = 'STU2020001'), (SELECT id FROM departments WHERE name = '컴퓨터공학과'),   'MAIN',   '2020-03-02'),
((SELECT id FROM users WHERE user_number = 'STU2020001'), (SELECT id FROM departments WHERE name = '소프트웨어학과'), 'DOUBLE', '2022-09-05'),
((SELECT id FROM users WHERE user_number = 'STU2021002'), (SELECT id FROM departments WHERE name = '전기전자공학과'), 'MAIN',   '2021-03-02'),
((SELECT id FROM users WHERE user_number = 'STU2022002'), (SELECT id FROM departments WHERE name = '경영학과'),       'MAIN',   '2022-03-02'),
((SELECT id FROM users WHERE user_number = 'STU2023002'), (SELECT id FROM departments WHERE name = '컴퓨터공학과'),   'MAIN',   '2023-03-06'),
((SELECT id FROM users WHERE user_number = 'STU2024001'), (SELECT id FROM departments WHERE name = '소프트웨어학과'), 'MAIN',   '2024-03-04');

-- ============================================================
-- 추가 강의
-- ============================================================

-- 2024년 2학기 추가 강의
INSERT INTO courses (course_code, name, credits, department_id, professor_id, semester_id, max_students, classroom, schedule) VALUES
('EE100', '회로이론',         3, (SELECT id FROM departments WHERE name = '전기전자공학과'), (SELECT id FROM users WHERE user_number = 'PRO2008001'), (SELECT id FROM semesters WHERE year = 2024 AND term = 2), 40, '공학관 301호', '월수 10:30-12:00'),
('BIZ100', '경영학원론',      3, (SELECT id FROM departments WHERE name = '경영학과'),       (SELECT id FROM users WHERE user_number = 'PRO2012001'), (SELECT id FROM semesters WHERE year = 2024 AND term = 2), 50, '경영관 101호', '화목 09:00-10:30'),
('CS103', '객체지향프로그래밍', 3, (SELECT id FROM departments WHERE name = '컴퓨터공학과'), (SELECT id FROM users WHERE user_number = 'PRO2010001'), (SELECT id FROM semesters WHERE year = 2024 AND term = 2), 35, '공학관 103호', '금 09:00-12:00');

-- 2025년 1학기 추가 강의
INSERT INTO courses (course_code, name, credits, department_id, professor_id, semester_id, max_students, classroom, schedule) VALUES
('EE101', '전자기학',         3, (SELECT id FROM departments WHERE name = '전기전자공학과'), (SELECT id FROM users WHERE user_number = 'PRO2008001'), (SELECT id FROM semesters WHERE year = 2025 AND term = 1), 40, '공학관 301호', '월수 10:30-12:00'),
('BIZ101', '마케팅원론',      3, (SELECT id FROM departments WHERE name = '경영학과'),       (SELECT id FROM users WHERE user_number = 'PRO2012001'), (SELECT id FROM semesters WHERE year = 2025 AND term = 1), 50, '경영관 101호', '화목 09:00-10:30'),
('CS202', '컴퓨터구조',       3, (SELECT id FROM departments WHERE name = '컴퓨터공학과'),   (SELECT id FROM users WHERE user_number = 'PRO2010001'), (SELECT id FROM semesters WHERE year = 2025 AND term = 1), 35, '공학관 103호', '금 09:00-12:00'),
('SW202', '네트워크프로그래밍', 3, (SELECT id FROM departments WHERE name = '소프트웨어학과'), (SELECT id FROM users WHERE user_number = 'PRO2015001'), (SELECT id FROM semesters WHERE year = 2025 AND term = 1), 30, '공학관 203호', '화목 15:00-16:30');

-- ============================================================
-- 추가 수강신청
-- ============================================================

-- 2024년 2학기 (완료)
INSERT INTO enrollments (student_id, course_id, status) VALUES
((SELECT id FROM users WHERE user_number = 'STU2020001'), (SELECT id FROM courses WHERE course_code = 'CS100' AND semester_id = (SELECT id FROM semesters WHERE year = 2024 AND term = 2)), 'COMPLETED'),
((SELECT id FROM users WHERE user_number = 'STU2020001'), (SELECT id FROM courses WHERE course_code = 'CS103' AND semester_id = (SELECT id FROM semesters WHERE year = 2024 AND term = 2)), 'COMPLETED'),
((SELECT id FROM users WHERE user_number = 'STU2020001'), (SELECT id FROM courses WHERE course_code = 'SW100' AND semester_id = (SELECT id FROM semesters WHERE year = 2024 AND term = 2)), 'COMPLETED'),
((SELECT id FROM users WHERE user_number = 'STU2021002'), (SELECT id FROM courses WHERE course_code = 'EE100' AND semester_id = (SELECT id FROM semesters WHERE year = 2024 AND term = 2)), 'COMPLETED'),
((SELECT id FROM users WHERE user_number = 'STU2021002'), (SELECT id FROM courses WHERE course_code = 'CS100' AND semester_id = (SELECT id FROM semesters WHERE year = 2024 AND term = 2)), 'COMPLETED'),
((SELECT id FROM users WHERE user_number = 'STU2022002'), (SELECT id FROM courses WHERE course_code = 'BIZ100' AND semester_id = (SELECT id FROM semesters WHERE year = 2024 AND term = 2)), 'COMPLETED'),
((SELECT id FROM users WHERE user_number = 'STU2022002'), (SELECT id FROM courses WHERE course_code = 'CS102' AND semester_id = (SELECT id FROM semesters WHERE year = 2024 AND term = 2)), 'COMPLETED'),
((SELECT id FROM users WHERE user_number = 'STU2023002'), (SELECT id FROM courses WHERE course_code = 'CS100' AND semester_id = (SELECT id FROM semesters WHERE year = 2024 AND term = 2)), 'COMPLETED'),
((SELECT id FROM users WHERE user_number = 'STU2023002'), (SELECT id FROM courses WHERE course_code = 'CS102' AND semester_id = (SELECT id FROM semesters WHERE year = 2024 AND term = 2)), 'COMPLETED');

-- 2025년 1학기 (현재)
INSERT INTO enrollments (student_id, course_id, status) VALUES
((SELECT id FROM users WHERE user_number = 'STU2020001'), (SELECT id FROM courses WHERE course_code = 'CS201' AND semester_id = (SELECT id FROM semesters WHERE year = 2025 AND term = 1)), 'ENROLLED'),
((SELECT id FROM users WHERE user_number = 'STU2020001'), (SELECT id FROM courses WHERE course_code = 'CS202' AND semester_id = (SELECT id FROM semesters WHERE year = 2025 AND term = 1)), 'ENROLLED'),
((SELECT id FROM users WHERE user_number = 'STU2020001'), (SELECT id FROM courses WHERE course_code = 'SW202' AND semester_id = (SELECT id FROM semesters WHERE year = 2025 AND term = 1)), 'ENROLLED'),
((SELECT id FROM users WHERE user_number = 'STU2021002'), (SELECT id FROM courses WHERE course_code = 'EE101' AND semester_id = (SELECT id FROM semesters WHERE year = 2025 AND term = 1)), 'ENROLLED'),
((SELECT id FROM users WHERE user_number = 'STU2021002'), (SELECT id FROM courses WHERE course_code = 'CS201' AND semester_id = (SELECT id FROM semesters WHERE year = 2025 AND term = 1)), 'ENROLLED'),
((SELECT id FROM users WHERE user_number = 'STU2022002'), (SELECT id FROM courses WHERE course_code = 'BIZ101' AND semester_id = (SELECT id FROM semesters WHERE year = 2025 AND term = 1)), 'ENROLLED'),
((SELECT id FROM users WHERE user_number = 'STU2022002'), (SELECT id FROM courses WHERE course_code = 'SW101'  AND semester_id = (SELECT id FROM semesters WHERE year = 2025 AND term = 1)), 'ENROLLED'),
((SELECT id FROM users WHERE user_number = 'STU2023002'), (SELECT id FROM courses WHERE course_code = 'CS101' AND semester_id = (SELECT id FROM semesters WHERE year = 2025 AND term = 1)), 'ENROLLED'),
((SELECT id FROM users WHERE user_number = 'STU2023002'), (SELECT id FROM courses WHERE course_code = 'CS202' AND semester_id = (SELECT id FROM semesters WHERE year = 2025 AND term = 1)), 'ENROLLED'),
((SELECT id FROM users WHERE user_number = 'STU2024001'), (SELECT id FROM courses WHERE course_code = 'SW101' AND semester_id = (SELECT id FROM semesters WHERE year = 2025 AND term = 1)), 'ENROLLED'),
((SELECT id FROM users WHERE user_number = 'STU2024001'), (SELECT id FROM courses WHERE course_code = 'CS101' AND semester_id = (SELECT id FROM semesters WHERE year = 2025 AND term = 1)), 'ENROLLED');

-- ============================================================
-- 추가 성적 (2024년 2학기 완료 수강)
-- ============================================================

INSERT INTO grades (enrollment_id, score, grade) VALUES
((SELECT e.id FROM enrollments e JOIN users u ON e.student_id = u.id JOIN courses c ON e.course_id = c.id WHERE u.user_number = 'STU2020001' AND c.course_code = 'CS100'), 98.00, 'A_PLUS'),
((SELECT e.id FROM enrollments e JOIN users u ON e.student_id = u.id JOIN courses c ON e.course_id = c.id WHERE u.user_number = 'STU2020001' AND c.course_code = 'CS103'), 91.00, 'A_ZERO'),
((SELECT e.id FROM enrollments e JOIN users u ON e.student_id = u.id JOIN courses c ON e.course_id = c.id WHERE u.user_number = 'STU2020001' AND c.course_code = 'SW100'), 87.00, 'B_PLUS'),
((SELECT e.id FROM enrollments e JOIN users u ON e.student_id = u.id JOIN courses c ON e.course_id = c.id WHERE u.user_number = 'STU2021002' AND c.course_code = 'EE100'), 83.00, 'B_PLUS'),
((SELECT e.id FROM enrollments e JOIN users u ON e.student_id = u.id JOIN courses c ON e.course_id = c.id WHERE u.user_number = 'STU2021002' AND c.course_code = 'CS100'), 76.00, 'C_PLUS'),
((SELECT e.id FROM enrollments e JOIN users u ON e.student_id = u.id JOIN courses c ON e.course_id = c.id WHERE u.user_number = 'STU2022002' AND c.course_code = 'BIZ100'), 92.00, 'A_ZERO'),
((SELECT e.id FROM enrollments e JOIN users u ON e.student_id = u.id JOIN courses c ON e.course_id = c.id WHERE u.user_number = 'STU2022002' AND c.course_code = 'CS102'), 65.00, 'C_ZERO'),
((SELECT e.id FROM enrollments e JOIN users u ON e.student_id = u.id JOIN courses c ON e.course_id = c.id WHERE u.user_number = 'STU2023002' AND c.course_code = 'CS100'), 80.00, 'B_ZERO'),
((SELECT e.id FROM enrollments e JOIN users u ON e.student_id = u.id JOIN courses c ON e.course_id = c.id WHERE u.user_number = 'STU2023002' AND c.course_code = 'CS102'), 72.00, 'C_PLUS');

-- ============================================================
-- 휴학 신청 샘플
-- ============================================================

INSERT INTO leave_requests (student_id, type, reason, target_semester_id, request_type, status, reviewed_by, reviewed_at) VALUES
((SELECT id FROM users WHERE user_number = 'STU2021001'),
 'MILITARY', '병역 의무 이행을 위한 군휴학 신청입니다.',
 (SELECT id FROM semesters WHERE year = 2025 AND term = 1),
 'LEAVE', 'APPROVED',
 (SELECT id FROM users WHERE user_number = 'ADM001'),
 '2025-02-10 10:00:00'),
((SELECT id FROM users WHERE user_number = 'STU2022002'),
 'GENERAL', '개인 사정으로 인한 휴학을 신청합니다.',
 (SELECT id FROM semesters WHERE year = 2025 AND term = 1),
 'LEAVE', 'PENDING',
 NULL, NULL);
