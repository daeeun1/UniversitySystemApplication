import { useState, useRef, useEffect } from 'react';
import { useAuth } from '../../context/AuthContext';
import { chatApi } from '../../services/api';
import DataCard from '../Cards/DataCard';

const QUICK_PROMPTS = {
  STUDENT: ['내 성적 보여줘', '이번 학기 수강 가능한 강의 목록', '졸업요건 확인', '내 정보 보여줘'],
  PROFESSOR: ['내 담당 강의 목록', '수강생 명단 조회', '내 정보 보여줘'],
  ADMIN: ['대기중인 휴학 신청 목록', '시스템 로그 보여줘', '내 정보 보여줘'],
  SYSTEM_ADMIN: ['시스템 로그 최근 20개', '내 정보 보여줘'],
};

export default function ChatInterface() {
  const { user, token } = useAuth();
  const [messages, setMessages]   = useState([
    { role: 'assistant', text: `안녕하세요, ${user?.name}님! 무엇을 도와드릴까요? 아래 빠른 메뉴를 선택하거나 직접 질문하세요.` }
  ]);
  const [input, setInput]         = useState('');
  const [loading, setLoading]     = useState(false);
  const [history, setHistory]     = useState([]);
  const bottomRef                 = useRef(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const sendMessage = async (text) => {
    if (!text.trim() || loading) return;
    const userMsg = { role: 'user', text };
    setMessages(prev => [...prev, userMsg]);
    setInput('');
    setLoading(true);

    try {
      const res = await chatApi.send(text, token, history);
      const { reply, function_called, data } = res.data;
      const assistantMsg = { role: 'assistant', text: reply, functionCalled: function_called, data };
      setMessages(prev => [...prev, assistantMsg]);
      setHistory(prev => [
        ...prev,
        { role: 'user', parts: [{ text }] },
        { role: 'model', parts: [{ text: reply }] },
      ]);
    } catch (err) {
      setMessages(prev => [...prev, {
        role: 'assistant',
        text: '죄송합니다. 요청 처리 중 오류가 발생했습니다.',
      }]);
    } finally {
      setLoading(false);
    }
  };

  const quickPrompts = QUICK_PROMPTS[user?.role] || QUICK_PROMPTS.STUDENT;

  return (
    <div style={styles.container}>
      {/* 메시지 영역 */}
      <div style={styles.messages}>
        {messages.map((msg, i) => (
          <div key={i} style={{ ...styles.msgRow, justifyContent: msg.role === 'user' ? 'flex-end' : 'flex-start' }}>
            {msg.role === 'assistant' && <div style={styles.avatar}>🤖</div>}
            <div style={{ maxWidth: '72%' }}>
              <div style={msg.role === 'user' ? styles.userBubble : styles.aiBubble}>
                {msg.text}
              </div>
              {msg.functionCalled && msg.data && (
                <DataCard functionName={msg.functionCalled} data={msg.data} />
              )}
            </div>
            {msg.role === 'user' && <div style={styles.avatarUser}>👤</div>}
          </div>
        ))}
        {loading && (
          <div style={{ ...styles.msgRow, justifyContent: 'flex-start' }}>
            <div style={styles.avatar}>🤖</div>
            <div style={styles.aiBubble}><LoadingDots /></div>
          </div>
        )}
        <div ref={bottomRef} />
      </div>

      {/* 빠른 메뉴 */}
      <div style={styles.quickArea}>
        {quickPrompts.map((q, i) => (
          <button key={i} style={styles.quickBtn} onClick={() => sendMessage(q)}>
            {q}
          </button>
        ))}
      </div>

      {/* 입력창 */}
      <div style={styles.inputArea}>
        <input
          style={styles.input}
          value={input}
          onChange={e => setInput(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && !e.shiftKey && sendMessage(input)}
          placeholder="메시지를 입력하세요... (Enter로 전송)"
          disabled={loading}
        />
        <button
          style={{ ...styles.sendBtn, opacity: loading ? 0.5 : 1 }}
          onClick={() => sendMessage(input)}
          disabled={loading}
        >
          ▶
        </button>
      </div>
    </div>
  );
}

function LoadingDots() {
  return (
    <span style={{ display: 'flex', gap: 4, alignItems: 'center', height: 20 }}>
      {[0, 1, 2].map(i => (
        <span key={i} style={{
          width: 6, height: 6, borderRadius: '50%', background: '#9e9e9e',
          animation: 'bounce 1.2s ease-in-out infinite',
          animationDelay: `${i * 0.2}s`,
        }} />
      ))}
      <style>{`@keyframes bounce{0%,80%,100%{transform:translateY(0)}40%{transform:translateY(-6px)}}`}</style>
    </span>
  );
}

const styles = {
  container: {
    display: 'flex', flexDirection: 'column', height: 'calc(100vh - 60px)',
    maxWidth: 900, margin: '0 auto', padding: '0 16px',
  },
  messages: { flex: 1, overflowY: 'auto', padding: '24px 0', display: 'flex', flexDirection: 'column', gap: 16 },
  msgRow:   { display: 'flex', alignItems: 'flex-start', gap: 10 },
  avatar:     { fontSize: 28, flexShrink: 0, marginTop: 2 },
  avatarUser: { fontSize: 24, flexShrink: 0, marginTop: 4 },
  userBubble: {
    background: 'linear-gradient(135deg,#0f3460,#533483)', color: '#fff',
    borderRadius: '18px 18px 4px 18px', padding: '12px 16px', fontSize: 14, lineHeight: 1.6,
  },
  aiBubble: {
    background: '#fff', color: '#1a1a2e',
    borderRadius: '18px 18px 18px 4px', padding: '12px 16px', fontSize: 14, lineHeight: 1.6,
    boxShadow: '0 2px 8px rgba(0,0,0,0.08)', border: '1px solid #e8eaf6',
  },
  quickArea: { display: 'flex', flexWrap: 'wrap', gap: 8, padding: '12px 0 8px' },
  quickBtn: {
    padding: '6px 14px', borderRadius: 16, border: '1.5px solid #c5cae9',
    background: '#fff', color: '#3949ab', fontSize: 13, cursor: 'pointer',
    fontWeight: 500, transition: 'all 0.15s',
  },
  inputArea: {
    display: 'flex', gap: 10, padding: '12px 0 20px', alignItems: 'center',
  },
  input: {
    flex: 1, padding: '14px 18px', borderRadius: 24,
    border: '2px solid #c5cae9', fontSize: 15, outline: 'none',
    background: '#fff', boxShadow: '0 2px 8px rgba(0,0,0,0.06)',
  },
  sendBtn: {
    width: 48, height: 48, borderRadius: '50%', border: 'none',
    background: 'linear-gradient(135deg,#0f3460,#533483)', color: '#fff',
    fontSize: 18, cursor: 'pointer', boxShadow: '0 2px 8px rgba(83,52,131,0.4)',
  },
};
