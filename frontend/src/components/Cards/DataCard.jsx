// 구조화된 UI 카드 — Gemini Function Calling 결과를 시각화
export default function DataCard({ functionName, data }) {
  if (!data || data.error) {
    return (
      <div style={styles.errorCard}>
        <span>⚠️</span>
        <span>{data?.error || '데이터를 불러오지 못했습니다.'}</span>
      </div>
    );
  }

  if (functionName === 'get_my_grades' && Array.isArray(data)) {
    return <GradesCard data={data} />;
  }
  if (functionName === 'get_course_list' && Array.isArray(data)) {
    return <CourseListCard data={data} />;
  }
  if (functionName === 'check_graduation_requirements') {
    return <GraduationCard data={data} />;
  }
  if (functionName === 'get_my_info') {
    return <InfoCard data={data} />;
  }
  if (functionName === 'get_my_lectures' && Array.isArray(data)) {
    return <LecturesCard data={data} />;
  }
  if (functionName === 'get_student_list' && Array.isArray(data)) {
    return <StudentListCard data={data} />;
  }
  if (functionName === 'get_leave_status' && Array.isArray(data)) {
    return <LeaveStatusCard data={data} />;
  }
  if (functionName === 'get_system_logs' && Array.isArray(data)) {
    return <SystemLogsCard data={data} />;
  }

  // 기본 JSON 카드
  return (
    <div style={styles.genericCard}>
      <pre style={styles.pre}>{JSON.stringify(data, null, 2)}</pre>
    </div>
  );
}

const GRADE_COLORS = {
  'A+': '#1b5e20', 'A0': '#2e7d32', 'B+': '#1565c0', 'B0': '#1976d2',
  'C+': '#e65100', 'C0': '#f57c00', 'D+': '#b71c1c', 'D0': '#c62828', 'F': '#000',
};

function GradesCard({ data }) {
  const total = data.reduce((s, r) => s + (r.score ? r.credits : 0), 0);
  return (
    <div style={styles.card}>
      <h3 style={styles.cardTitle}>📊 성적 조회</h3>
      <table style={styles.table}>
        <thead>
          <tr style={styles.thead}>
            {['강의명', '학점', '학기', '등급', '점수'].map(h => (
              <th key={h} style={styles.th}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.map((r, i) => (
            <tr key={i} style={i % 2 === 0 ? styles.trEven : styles.trOdd}>
              <td style={styles.td}>{r.courseName}</td>
              <td style={{ ...styles.td, textAlign: 'center' }}>{r.credits}</td>
              <td style={{ ...styles.td, textAlign: 'center' }}>{r.semester}</td>
              <td style={{ ...styles.td, textAlign: 'center' }}>
                <span style={{
                  ...styles.gradeBadge,
                  background: GRADE_COLORS[r.grade] || '#888',
                }}>
                  {r.grade || '-'}
                </span>
              </td>
              <td style={{ ...styles.td, textAlign: 'center' }}>
                {r.score != null ? `${r.score}점` : '-'}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <p style={styles.cardFooter}>총 {data.length}개 강의</p>
    </div>
  );
}

function CourseListCard({ data }) {
  return (
    <div style={styles.card}>
      <h3 style={styles.cardTitle}>📚 수강 가능 강의</h3>
      <div style={styles.courseGrid}>
        {data.map((c, i) => (
          <div key={i} style={styles.courseItem}>
            <div style={styles.courseHeader}>
              <span style={styles.courseCode}>{c.courseCode}</span>
              <span style={styles.creditBadge}>{c.credits}학점</span>
            </div>
            <p style={styles.courseName}>{c.name}</p>
            <p style={styles.courseMeta}>👤 {c.professor} · {c.department}</p>
            <p style={styles.courseMeta}>🕐 {c.schedule || '-'} · {c.classroom || '-'}</p>
            <div style={styles.enrollBar}>
              <div
                style={{
                  ...styles.enrollFill,
                  width: `${Math.min(100, (c.enrolledCount / c.maxStudents) * 100)}%`,
                  background: c.enrolledCount >= c.maxStudents ? '#e53935' : '#43a047',
                }}
              />
            </div>
            <p style={styles.enrollText}>
              {c.enrolledCount} / {c.maxStudents}명
              {c.enrolledCount >= c.maxStudents && ' (마감)'}
            </p>
          </div>
        ))}
      </div>
    </div>
  );
}

function GraduationCard({ data }) {
  const pct = Math.min(100, Math.round((data.totalCredits / data.requiredCredits) * 100));
  return (
    <div style={styles.card}>
      <h3 style={styles.cardTitle}>🎓 졸업요건 확인</h3>
      <div style={{ textAlign: 'center', padding: '16px 0' }}>
        <div style={{
          ...styles.statusBadge,
          background: data.satisfied ? '#e8f5e9' : '#fff3e0',
          color: data.satisfied ? '#2e7d32' : '#e65100',
        }}>
          {data.satisfied ? '✅ 졸업요건 충족' : '⏳ 충족 중'}
        </div>
        <div style={styles.progressOuter}>
          <div style={{ ...styles.progressInner, width: `${pct}%` }} />
        </div>
        <p style={styles.progressLabel}>{data.totalCredits} / {data.requiredCredits} 학점 ({pct}%)</p>
        {!data.satisfied && (
          <p style={{ color: '#e65100', fontSize: 14 }}>잔여 {data.remaining}학점 필요</p>
        )}
      </div>
    </div>
  );
}

function InfoCard({ data }) {
  const rows = Object.entries(data).filter(([k]) => k !== 'passwordHash');
  const labels = {
    userNumber: '학번/교번', name: '이름', email: '이메일', phone: '연락처',
    role: '역할', admissionYear: '입학년도', grade: '학년',
    status: '학적상태', totalCredits: '취득학점', mainDepartment: '주전공',
  };
  return (
    <div style={styles.card}>
      <h3 style={styles.cardTitle}>👤 개인정보</h3>
      <dl style={styles.dl}>
        {rows.map(([k, v]) => (
          <div key={k} style={styles.dlRow}>
            <dt style={styles.dt}>{labels[k] || k}</dt>
            <dd style={styles.dd}>{String(v)}</dd>
          </div>
        ))}
      </dl>
    </div>
  );
}

function LecturesCard({ data }) {
  return (
    <div style={styles.card}>
      <h3 style={styles.cardTitle}>📖 담당 강의</h3>
      {data.map((c, i) => (
        <div key={i} style={styles.lectureItem}>
          <div style={styles.lectureHeader}>
            <span style={styles.courseCode}>{c.courseCode}</span>
            <span style={styles.courseName}>{c.name}</span>
            <span style={styles.creditBadge}>{c.credits}학점</span>
          </div>
          <p style={styles.courseMeta}>
            📅 {c.semester} · 🕐 {c.schedule || '-'} · 🏫 {c.classroom || '-'}
          </p>
          <p style={styles.courseMeta}>수강생 {c.enrolledCount}명</p>
        </div>
      ))}
    </div>
  );
}

function StudentListCard({ data }) {
  return (
    <div style={styles.card}>
      <h3 style={styles.cardTitle}>👥 수강생 목록</h3>
      <table style={styles.table}>
        <thead>
          <tr style={styles.thead}>
            {['학번', '이름', '등급', '점수'].map(h => <th key={h} style={styles.th}>{h}</th>)}
          </tr>
        </thead>
        <tbody>
          {data.map((s, i) => (
            <tr key={i} style={i % 2 === 0 ? styles.trEven : styles.trOdd}>
              <td style={styles.td}>{s.studentNumber}</td>
              <td style={styles.td}>{s.name}</td>
              <td style={{ ...styles.td, textAlign: 'center' }}>
                {s.grade && s.grade !== '미입력'
                  ? <span style={{ ...styles.gradeBadge, background: GRADE_COLORS[s.grade] || '#888' }}>{s.grade}</span>
                  : <span style={{ color: '#aaa' }}>미입력</span>
                }
              </td>
              <td style={{ ...styles.td, textAlign: 'center' }}>
                {s.score != null ? `${s.score}점` : '-'}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function LeaveStatusCard({ data }) {
  const statusColor = { PENDING: '#f57c00', APPROVED: '#2e7d32', REJECTED: '#c62828' };
  const statusLabel = { PENDING: '처리중', APPROVED: '승인', REJECTED: '반려' };
  return (
    <div style={styles.card}>
      <h3 style={styles.cardTitle}>📋 휴학/복학 현황</h3>
      {data.length === 0
        ? <p style={{ color: '#aaa', padding: '16px 0' }}>신청 내역이 없습니다.</p>
        : data.map((r, i) => (
          <div key={i} style={styles.leaveItem}>
            <div style={styles.leaveHeader}>
              <span>{r.requestType === 'LEAVE' ? '🏖️ 휴학' : '🔄 복학'}</span>
              <span style={{ ...styles.statusPill, background: statusColor[r.status] + '22', color: statusColor[r.status] }}>
                {statusLabel[r.status]}
              </span>
            </div>
            <p style={styles.leaveMeta}>대상학기: {r.targetSemester} · 유형: {r.type}</p>
            <p style={styles.leaveReason}>{r.reason}</p>
          </div>
        ))
      }
    </div>
  );
}

function SystemLogsCard({ data }) {
  return (
    <div style={styles.card}>
      <h3 style={styles.cardTitle}>🖥️ 시스템 로그</h3>
      <table style={styles.table}>
        <thead>
          <tr style={styles.thead}>
            {['시각', '사용자', '함수', '상태', 'RBAC차단'].map(h => <th key={h} style={styles.th}>{h}</th>)}
          </tr>
        </thead>
        <tbody>
          {data.map((log, i) => (
            <tr key={i} style={log.isBlocked ? styles.trBlocked : (i % 2 === 0 ? styles.trEven : styles.trOdd)}>
              <td style={styles.td}>{new Date(log.createdAt).toLocaleString('ko-KR')}</td>
              <td style={styles.td}>{log.user}</td>
              <td style={styles.td}><code>{log.functionName}</code></td>
              <td style={{ ...styles.td, textAlign: 'center' }}>{log.responseStatus}</td>
              <td style={{ ...styles.td, textAlign: 'center' }}>{log.isBlocked ? '🚫' : '✅'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

const styles = {
  card: {
    background: '#f8f9ff', borderRadius: 12, padding: '16px 20px',
    border: '1px solid #e8eaf6', marginTop: 8,
  },
  cardTitle: { fontSize: 15, fontWeight: 700, color: '#1a1a2e', marginBottom: 12 },
  cardFooter: { fontSize: 12, color: '#888', marginTop: 8, textAlign: 'right' },
  errorCard: {
    display: 'flex', gap: 8, alignItems: 'center', padding: '12px 16px',
    background: '#ffebee', borderRadius: 10, color: '#c62828', fontSize: 14,
  },
  genericCard: { background: '#f5f5f5', borderRadius: 10, padding: 12, marginTop: 8 },
  pre: { fontSize: 12, overflow: 'auto', maxHeight: 200 },
  table: { width: '100%', borderCollapse: 'collapse', fontSize: 13 },
  thead: { background: '#e8eaf6' },
  th: { padding: '8px 12px', textAlign: 'left', fontWeight: 600, color: '#3949ab', fontSize: 12 },
  td: { padding: '8px 12px', color: '#333' },
  trEven: { background: '#fff' },
  trOdd: { background: '#f5f6ff' },
  trBlocked: { background: '#ffebee' },
  gradeBadge: {
    display: 'inline-block', padding: '2px 8px', borderRadius: 8,
    color: '#fff', fontSize: 12, fontWeight: 700,
  },
  courseGrid: { display: 'flex', flexDirection: 'column', gap: 10 },
  courseItem: {
    background: '#fff', borderRadius: 10, padding: '12px 16px',
    border: '1px solid #e0e0e0',
  },
  courseHeader: { display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 },
  courseCode: { fontSize: 11, color: '#3949ab', fontWeight: 700, background: '#e8eaf6', padding: '2px 8px', borderRadius: 6 },
  courseName: { fontWeight: 600, fontSize: 14, color: '#1a1a2e', marginBottom: 4 },
  creditBadge: { marginLeft: 'auto', fontSize: 11, color: '#388e3c', fontWeight: 700, background: '#e8f5e9', padding: '2px 8px', borderRadius: 6 },
  courseMeta: { fontSize: 12, color: '#666', marginTop: 2 },
  enrollBar: { height: 4, background: '#e0e0e0', borderRadius: 2, marginTop: 8 },
  enrollFill: { height: '100%', borderRadius: 2, transition: 'width 0.5s' },
  enrollText: { fontSize: 11, color: '#888', marginTop: 4 },
  progressOuter: { height: 12, background: '#e0e0e0', borderRadius: 6, margin: '16px 0 8px', overflow: 'hidden' },
  progressInner: { height: '100%', background: 'linear-gradient(90deg,#3949ab,#5c6bc0)', borderRadius: 6, transition: 'width 0.8s' },
  progressLabel: { fontSize: 18, fontWeight: 700, color: '#1a1a2e', margin: '8px 0' },
  statusBadge: { display: 'inline-block', padding: '8px 20px', borderRadius: 20, fontWeight: 700, fontSize: 15, marginBottom: 16 },
  dl: { display: 'flex', flexDirection: 'column', gap: 8 },
  dlRow: { display: 'flex', gap: 16, padding: '6px 0', borderBottom: '1px solid #f0f0f0' },
  dt: { width: 100, fontSize: 13, color: '#888', fontWeight: 600, flexShrink: 0 },
  dd: { fontSize: 13, color: '#1a1a2e' },
  lectureItem: { background: '#fff', borderRadius: 10, padding: '12px 16px', border: '1px solid #e0e0e0', marginBottom: 8 },
  lectureHeader: { display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 },
  leaveItem: { background: '#fff', borderRadius: 10, padding: '12px 16px', border: '1px solid #e0e0e0', marginBottom: 8 },
  leaveHeader: { display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 6 },
  leaveMeta: { fontSize: 12, color: '#666', marginBottom: 4 },
  leaveReason: { fontSize: 13, color: '#333' },
  statusPill: { padding: '2px 10px', borderRadius: 10, fontSize: 12, fontWeight: 600 },
};
