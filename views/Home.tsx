
import React from 'react';
import { ViewState, UserStats, UserProfile } from '../types';
import { Card } from '../components/Common';
import { 
  Navigation2, 
  Layers, 
  PenTool, 
  BrainCircuit, 
  Calendar, 
  BarChart3, 
  History as HistoryIcon,
  ChevronRight,
  Flame
} from 'lucide-react';

interface HomeProps {
  setView: (v: ViewState) => void;
  userStats: UserStats;
  profile?: UserProfile;
}

export const Home: React.FC<HomeProps> = ({ setView, userStats, profile }) => {
  const modules = [
    { id: 'GPS', label: 'GPS', desc: 'Plano Inteligente', icon: <Navigation2 className="text-[#D4A54A]" />, view: 'GPS' },
    { id: 'EXERCISES', label: 'Exercícios', desc: 'Praticar conteúdo', icon: <Layers className="text-[#D4A54A]" />, view: 'PRACTICE' },
    { id: 'ESSAY', label: 'Redação', desc: 'Treinar escrita', icon: <PenTool className="text-[#D4A54A]" />, view: 'ESSAY' },
    { id: 'RESUCARDS', label: 'ResuCards', desc: 'Repetição Espaçada', icon: <BrainCircuit className="text-[#D4A54A]" />, view: 'RESUCARDS' },
    { id: 'SCHEDULE', label: 'Cronograma', desc: 'Gestão de tempo', icon: <Calendar className="text-[#D4A54A]" />, view: 'SCHEDULE' },
    { id: 'PERFORMANCE', label: 'Desempenho', desc: 'Análise de dados', icon: <BarChart3 className="text-[#D4A54A]" />, view: 'PERFORMANCE' },
    { id: 'HISTORY', label: 'Histórico', desc: 'Suas atividades', icon: <HistoryIcon className="text-[#D4A54A]" />, view: 'HISTORY' },
  ];

  return (
    <div className="space-y-8 pt-4 animate-fade-in">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-black text-white">Olá, {profile?.name || 'Doutor(a)'}</h2>
          <div className="flex items-center gap-2 mt-1">
             <span className="text-xs font-bold text-[#D4A54A] uppercase tracking-widest">{profile?.targetExams[0] || 'ENAMED'}</span>
             <div className="w-1 h-1 bg-[#1F1F1F] rounded-full"></div>
             <div className="flex items-center gap-1 text-[#D4A54A]">
                <Flame size={14} fill="currentColor" />
                <span className="text-xs font-bold">{userStats.streak} dias</span>
             </div>
          </div>
        </div>
        <div className="w-12 h-12 rounded-full border-2 border-[#D4A54A] p-0.5">
           <div className="w-full h-full bg-[#1F1F1F] rounded-full flex items-center justify-center text-[#D4A54A] font-bold">
              {profile?.name.charAt(0) || 'D'}
           </div>
        </div>
      </div>

      {/* Main Grid */}
      <div className="grid grid-cols-2 gap-4">
        {modules.map((m, idx) => (
          <button 
            key={m.id} 
            onClick={() => setView(m.view as ViewState)}
            className={`
              flex flex-col items-start p-5 rounded-3xl bg-[#0A0A0A] border border-[#1F1F1F] hover:border-[#D4A54A] transition-all group
              ${idx === 0 ? 'col-span-2 aspect-[2/0.8]' : 'aspect-square'}
            `}
          >
            <div className="w-10 h-10 rounded-xl bg-[#D4A54A]/10 flex items-center justify-center mb-auto group-hover:scale-110 transition-transform">
              {m.icon}
            </div>
            <div className="text-left">
              <h3 className="text-lg font-bold text-white">{m.label}</h3>
              <p className="text-[10px] text-[#555] font-medium uppercase tracking-wider">{m.desc}</p>
            </div>
          </button>
        ))}
      </div>

      {/* Area Hoje */}
      <div className="space-y-4">
         <h3 className="text-xs font-bold text-[#555] uppercase tracking-widest">Atividade para Hoje</h3>
         <Card className="flex items-center justify-between p-6 bg-gradient-to-r from-[#0A0A0A] to-[#111]">
            <div className="flex items-center gap-4">
               <div className="w-12 h-12 rounded-full bg-[#D4A54A]/20 flex items-center justify-center">
                  <BrainCircuit className="text-[#D4A54A]" size={24} />
               </div>
               <div>
                  <h4 className="text-white font-bold">Revisão Diária</h4>
                  <p className="text-xs text-[#777]">15 ResuCards pendentes</p>
               </div>
            </div>
            <button className="p-2 bg-[#D4A54A] rounded-full text-black">
               <ChevronRight size={20} />
            </button>
         </Card>
      </div>
    </div>
  );
};
