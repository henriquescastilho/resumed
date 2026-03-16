
import React, { useState, useEffect } from 'react';
import { ViewState, Flashcard, UserStats, Theme, UserProfile } from './types';
import { MOCK_FLASHCARDS } from './constants';
import { calculateNextReview, addXP } from './services/studySystem';
import { Layout } from './components/Layout';
import { Onboarding } from './views/Onboarding';
import { Home } from './views/Home';
import { GPS } from './views/GPS';
import { Essay } from './views/Essay';
import { ResuCards } from './views/ResuCards';
import { Practice } from './views/Practice';
import { History } from './views/History';
import { Performance } from './views/Performance';
import { Grey } from './views/Grey';
import { Plan } from './views/Plan';
import { Connect } from './views/Connect';
import { Logo } from './components/Logo';

const Splash: React.FC<{ onFinish: () => void }> = ({ onFinish }) => {
  useEffect(() => {
    const timer = setTimeout(onFinish, 2500);
    return () => clearTimeout(timer);
  }, [onFinish]);

  return (
    <div className="fixed inset-0 bg-black flex items-center justify-center z-50">
      <div className="relative flex flex-col items-center gap-4">
        <Logo size={120} className="animate-pulse drop-shadow-[0_0_15px_rgba(212,165,74,0.5)]" />
        <h1 className="text-4xl font-black tracking-widest text-[#D4A54A]">RESUMED</h1>
        <div className="absolute -inset-20 bg-[#D4A54A] blur-[100px] opacity-10"></div>
      </div>
    </div>
  );
};

export default function App() {
  const [view, setView] = useState<ViewState>('SPLASH');
  const [theme, setTheme] = useState<Theme>('dark');
  const [profile, setProfile] = useState<UserProfile | undefined>();
  
  const [flashcards, setFlashcards] = useState<Flashcard[]>(MOCK_FLASHCARDS);
  const [userStats, setUserStats] = useState<UserStats>({
    xp: 1240, level: 2, streak: 12, badges: ['b1'], cardsReviewedToday: 0
  });

  const handleCardReview = (cardId: string, rating: 'fail' | 'hard' | 'good' | 'easy') => {
    setFlashcards(prev => prev.map(card => card.id === cardId ? calculateNextReview(card, rating) : card));
    setUserStats(prev => {
      const { newStats } = addXP(prev, rating === 'easy' ? 20 : 15);
      return { ...newStats, cardsReviewedToday: prev.cardsReviewedToday + 1 };
    });
  };

  const renderView = () => {
    if (view.startsWith('ONBOARDING')) return <Onboarding setView={setView} setProfile={setProfile} />;
    
    switch (view) {
      case 'HOME': return <Home setView={setView} userStats={userStats} profile={profile} />;
      case 'GPS': return <GPS />;
      case 'PRACTICE': return <Practice setView={setView} />;
      case 'ESSAY': return <Essay setView={setView} />;
      case 'RESUCARDS': return <ResuCards flashcards={flashcards} onReview={handleCardReview} />;
      case 'HISTORY': return <History />;
      case 'PERFORMANCE': return <Performance userStats={userStats} />;
      case 'GREY': return <Grey />;
      case 'PLAN': return <Plan />;
      case 'CONNECT': return <Connect />;
      case 'SCHEDULE': return <History />; // Mocked to history for brevity
      default: return <Home setView={setView} userStats={userStats} profile={profile} />;
    }
  };

  if (view === 'SPLASH') return <Splash onFinish={() => setView('ONBOARDING_WELCOME')} />;

  const noNavViews: ViewState[] = [
    'ONBOARDING_WELCOME', 'ONBOARDING_EXAMS', 'ONBOARDING_DAYS', 
    'ONBOARDING_HOURS', 'ONBOARDING_DISTRIBUTION', 'ONBOARDING_ASSESSMENT', 
    'ONBOARDING_PROCESSING', 'SPLASH'
  ];

  return (
    <Layout currentView={view} setView={setView} showNav={!noNavViews.includes(view)} theme={theme} toggleTheme={() => setTheme(t => t === 'dark' ? 'light' : 'dark')}>
      {renderView()}
    </Layout>
  );
}
