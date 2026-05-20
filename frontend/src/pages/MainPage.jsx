import { useState } from 'react';
import Header from '../components/Layout/Header';
import ChatInterface from '../components/Chat/ChatInterface';
import ClassicPage from './ClassicPage';

export default function MainPage() {
  const [activeTab, setActiveTab] = useState('chat');

  return (
    <div style={{ minHeight: '100vh', background: '#f0f2f5' }}>
      <Header activeTab={activeTab} onTabChange={setActiveTab} />
      {activeTab === 'chat' ? <ChatInterface /> : <ClassicPage />}
    </div>
  );
}
