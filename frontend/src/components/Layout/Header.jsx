import { useAuth } from '../../context/AuthContext';
import { useNavigate } from 'react-router-dom';

const ROLE_LABELS = {
  STUDENT: '학생', PROFESSOR: '교수', ADMIN: '행정직원', SYSTEM_ADMIN: '시스템관리자',
};

export default function Header({ activeTab, onTabChange }) {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => { logout(); navigate('/login'); };

  return (
    <header style={styles.header}>
      <div style={styles.left}>
        <span style={styles.logo}>🎓</span>
        <span style={styles.title}>대학정보시스템</span>
        <nav style={styles.nav}>
          {[{ id: 'chat', label: '🤖 AI 어시스턴트' }, { id: 'classic', label: '📋 기존 메뉴' }].map(tab => (
            <button
              key={tab.id}
              style={{ ...styles.tab, ...(activeTab === tab.id ? styles.tabActive : {}) }}
              onClick={() => onTabChange(tab.id)}
            >
              {tab.label}
            </button>
          ))}
        </nav>
      </div>
      <div style={styles.right}>
        <div style={styles.userInfo}>
          <span style={styles.roleBadge}>{ROLE_LABELS[user?.role] || user?.role}</span>
          <span style={styles.userName}>{user?.name}</span>
          <span style={styles.userNumber}>{user?.userNumber}</span>
        </div>
        <button style={styles.logoutBtn} onClick={handleLogout}>로그아웃</button>
      </div>
    </header>
  );
}

const styles = {
  header: {
    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    padding: '0 24px', height: 60,
    background: 'linear-gradient(135deg, #1a1a2e, #0f3460)',
    boxShadow: '0 2px 12px rgba(0,0,0,0.3)', position: 'sticky', top: 0, zIndex: 100,
  },
  left:   { display: 'flex', alignItems: 'center', gap: 16 },
  logo:   { fontSize: 24 },
  title:  { color: '#fff', fontWeight: 700, fontSize: 17, whiteSpace: 'nowrap' },
  nav:    { display: 'flex', gap: 4, marginLeft: 16 },
  tab: {
    padding: '6px 16px', borderRadius: 20, border: 'none',
    background: 'transparent', color: 'rgba(255,255,255,0.6)',
    cursor: 'pointer', fontSize: 13, fontWeight: 500, transition: 'all 0.2s',
  },
  tabActive: { background: 'rgba(255,255,255,0.15)', color: '#fff' },
  right:  { display: 'flex', alignItems: 'center', gap: 16 },
  userInfo: { display: 'flex', alignItems: 'center', gap: 8 },
  roleBadge: {
    padding: '3px 10px', borderRadius: 12,
    background: 'rgba(255,255,255,0.15)', color: '#fff', fontSize: 11, fontWeight: 600,
  },
  userName:   { color: '#fff', fontSize: 14, fontWeight: 600 },
  userNumber: { color: 'rgba(255,255,255,0.5)', fontSize: 12 },
  logoutBtn: {
    padding: '6px 14px', borderRadius: 8, border: '1px solid rgba(255,255,255,0.3)',
    background: 'transparent', color: '#fff', fontSize: 13, cursor: 'pointer',
  },
};
