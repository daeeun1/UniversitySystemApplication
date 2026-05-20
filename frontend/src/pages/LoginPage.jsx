import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { authApi } from '../services/api';

export default function LoginPage() {
  const [userNumber, setUserNumber] = useState('');
  const [password, setPassword]     = useState('');
  const [error, setError]           = useState('');
  const [loading, setLoading]       = useState(false);
  const { login } = useAuth();
  const navigate  = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const res = await authApi.login(userNumber, password);
      const { token, ...userInfo } = res.data.data;
      login(token, userInfo);
      navigate('/chat');
    } catch (err) {
      setError(err.response?.data?.message || '로그인에 실패했습니다.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <div style={styles.logo}>
          <span style={styles.logoIcon}>🎓</span>
          <h1 style={styles.logoText}>대학정보시스템</h1>
          <p style={styles.logoSub}>University Information System</p>
        </div>

        <form onSubmit={handleSubmit} style={styles.form}>
          <div style={styles.field}>
            <label style={styles.label}>학번 / 교번</label>
            <input
              style={styles.input}
              value={userNumber}
              onChange={e => setUserNumber(e.target.value)}
              placeholder="학번 또는 교번을 입력하세요"
              required
            />
          </div>
          <div style={styles.field}>
            <label style={styles.label}>비밀번호</label>
            <input
              style={styles.input}
              type="password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              placeholder="비밀번호를 입력하세요"
              required
            />
          </div>
          {error && <p style={styles.error}>{error}</p>}
          <button style={styles.btn} type="submit" disabled={loading}>
            {loading ? '로그인 중...' : '로그인'}
          </button>
        </form>

        <p style={styles.hint}>AI 어시스턴트가 도와드립니다 ✨</p>
      </div>
    </div>
  );
}

const styles = {
  container: {
    minHeight: '100vh', display: 'flex', alignItems: 'center',
    justifyContent: 'center',
    background: 'linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%)',
  },
  card: {
    background: '#fff', borderRadius: 20, padding: '48px 40px',
    width: 420, boxShadow: '0 20px 60px rgba(0,0,0,0.3)',
  },
  logo: { textAlign: 'center', marginBottom: 36 },
  logoIcon: { fontSize: 48 },
  logoText: { fontSize: 24, fontWeight: 700, color: '#1a1a2e', marginTop: 8 },
  logoSub: { fontSize: 13, color: '#888', marginTop: 4 },
  form: { display: 'flex', flexDirection: 'column', gap: 16 },
  field: { display: 'flex', flexDirection: 'column', gap: 6 },
  label: { fontSize: 13, fontWeight: 600, color: '#444' },
  input: {
    padding: '12px 16px', borderRadius: 10, border: '1.5px solid #e0e0e0',
    fontSize: 15, outline: 'none', transition: 'border-color 0.2s',
  },
  error: { color: '#e53935', fontSize: 13, textAlign: 'center' },
  btn: {
    padding: '14px', borderRadius: 10, border: 'none',
    background: 'linear-gradient(135deg, #0f3460, #533483)',
    color: '#fff', fontSize: 16, fontWeight: 600, cursor: 'pointer',
    marginTop: 8,
  },
  hint: { textAlign: 'center', color: '#aaa', fontSize: 13, marginTop: 24 },
};
