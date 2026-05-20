import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { academicApi, studentApi, lectureApi, adminApi } from '../services/api';

// 기존 UI 메뉴 — 역할별로 표시 항목이 다름
export default function ClassicPage() {
  const { user } = useAuth();
  const [activeMenu, setActiveMenu] = useState(null);
  const [data, setData]   = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const menus = {
    STUDENT: [
      { id: 'grades',       label: '📊 성적 조회',      fetch: () => academicApi.getGrades() },
      { id: 'courses',      label: '📚 강의 목록',       fetch: () => academicApi.getCourses('2025-1') },
      { id: 'graduation',   label: '🎓 졸업요건 확인',   fetch: () => academicApi.graduation() },
      { id: 'info',         label: '👤 내 정보',          fetch: () => studentApi.getInfo() },
      { id: 'leaveStatus',  label: '📋 휴학/복학 현황', fetch: () => studentApi.getLeaveStatus() },
    ],
    PROFESSOR: [
      { id: 'lectures',     label: '📖 담당 강의',       fetch: () => lectureApi.getMyLectures() },
      { id: 'info',         label: '👤 내 정보',          fetch: () => studentApi.getInfo() },
    ],
    ADMIN: [
      { id: 'logs',         label: '🖥️ 시스템 로그',    fetch: () => adminApi.getLogs(30) },
      { id: 'info',         label: '👤 내 정보',          fetch: () => studentApi.getInfo() },
    ],
    SYSTEM_ADMIN: [
      { id: 'logs',         label: '🖥️ 시스템 로그',    fetch: () => adminApi.getLogs(50) },
      { id: 'info',         label: '👤 내 정보',          fetch: () => studentApi.getInfo() },
    ],
  };

  const roleMenus = menus[user?.role] || menus.STUDENT;

  const handleMenu = async (menu) => {
    setActiveMenu(menu.id);
    setLoading(true);
    setError('');
    setData(null);
    try {
      const res = await menu.fetch();
      setData(res.data?.data ?? res.data);
    } catch (e) {
      setError(e.response?.data?.message || '데이터 조회에 실패했습니다.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={styles.container}>
      <aside style={styles.sidebar}>
        <p style={styles.sidebarTitle}>메뉴</p>
        {roleMenus.map(m => (
          <button
            key={m.id}
            style={{ ...styles.menuBtn, ...(activeMenu === m.id ? styles.menuBtnActive : {}) }}
            onClick={() => handleMenu(m)}
          >
            {m.label}
          </button>
        ))}
      </aside>

      <main style={styles.main}>
        {!activeMenu && (
          <div style={styles.empty}>
            <p style={styles.emptyIcon}>📋</p>
            <p style={styles.emptyText}>왼쪽 메뉴를 선택하세요</p>
            <p style={styles.emptyHint}>또는 상단의 AI 어시스턴트 탭을 이용하세요</p>
          </div>
        )}
        {loading && <div style={styles.loading}>⏳ 데이터를 불러오는 중...</div>}
        {error && <div style={styles.error}>⚠️ {error}</div>}
        {data && !loading && <DataDisplay data={data} menuId={activeMenu} />}
      </main>
    </div>
  );
}

function DataDisplay({ data, menuId }) {
  if (Array.isArray(data)) {
    if (data.length === 0) return <p style={{ color: '#aaa', padding: 24 }}>데이터가 없습니다.</p>;
    const keys = Object.keys(data[0]);
    return (
      <div style={{ overflowX: 'auto' }}>
        <table style={styles.table}>
          <thead>
            <tr>{keys.map(k => <th key={k} style={styles.th}>{k}</th>)}</tr>
          </thead>
          <tbody>
            {data.map((row, i) => (
              <tr key={i} style={{ background: i % 2 === 0 ? '#fff' : '#f5f6ff' }}>
                {keys.map(k => <td key={k} style={styles.td}>{String(row[k] ?? '-')}</td>)}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  }
  return (
    <dl style={styles.dl}>
      {Object.entries(data).map(([k, v]) => (
        <div key={k} style={styles.dlRow}>
          <dt style={styles.dt}>{k}</dt>
          <dd style={styles.dd}>{String(v)}</dd>
        </div>
      ))}
    </dl>
  );
}

const styles = {
  container: { display: 'flex', height: 'calc(100vh - 60px)' },
  sidebar: {
    width: 220, background: '#fff', borderRight: '1px solid #e8eaf6',
    padding: '24px 12px', display: 'flex', flexDirection: 'column', gap: 4,
  },
  sidebarTitle: { fontSize: 11, fontWeight: 700, color: '#9e9e9e', padding: '0 8px 8px', textTransform: 'uppercase', letterSpacing: 1 },
  menuBtn: {
    padding: '10px 14px', borderRadius: 10, border: 'none',
    background: 'transparent', color: '#444', fontSize: 13,
    cursor: 'pointer', textAlign: 'left', fontWeight: 500,
  },
  menuBtnActive: { background: '#e8eaf6', color: '#3949ab', fontWeight: 700 },
  main: { flex: 1, overflowY: 'auto', padding: 32 },
  empty: { display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '60vh' },
  emptyIcon: { fontSize: 64 },
  emptyText: { fontSize: 18, color: '#444', marginTop: 16, fontWeight: 600 },
  emptyHint: { fontSize: 13, color: '#aaa', marginTop: 8 },
  loading: { color: '#888', fontSize: 15, padding: 24 },
  error: { color: '#c62828', background: '#ffebee', padding: '12px 16px', borderRadius: 10, fontSize: 14 },
  table: { width: '100%', borderCollapse: 'collapse', fontSize: 13, background: '#fff', borderRadius: 10, overflow: 'hidden' },
  th: { padding: '10px 14px', background: '#e8eaf6', fontWeight: 700, color: '#3949ab', textAlign: 'left' },
  td: { padding: '10px 14px', borderBottom: '1px solid #f0f0f0', color: '#333' },
  dl: { display: 'flex', flexDirection: 'column', gap: 8, maxWidth: 500 },
  dlRow: { display: 'flex', gap: 16, padding: '8px 0', borderBottom: '1px solid #f0f0f0' },
  dt: { width: 140, fontWeight: 600, color: '#888', fontSize: 13, flexShrink: 0 },
  dd: { fontSize: 13, color: '#1a1a2e' },
};
