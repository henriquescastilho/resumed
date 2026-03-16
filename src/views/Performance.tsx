
import React, { useState } from 'react';
import { Card } from '../components/Common';
import { UserStats, Badge } from '../types';
import { BADGES, XP_PER_LEVEL } from '../constants';
import { ResponsiveContainer, RadarChart, PolarGrid, PolarAngleAxis, Radar, BarChart, Bar, XAxis, Tooltip } from 'recharts';
import { Trophy, AlertTriangle, Shield, Flag, Book, HeartPulse, Lock, Star } from 'lucide-react';

const IconMap: Record<string, any> = {
  Shield, Flag, Book, HeartPulse
};

interface PerformanceProps {
  userStats: UserStats;
}

export const Performance: React.FC<PerformanceProps> = ({ userStats }) => {
  const [tab, setTab] = useState<'subject' | 'time'>('subject');

  const radarData = [
    { subject: 'Clínica', A: 120, fullMark: 150 },
    { subject: 'Cirurgia', A: 98, fullMark: 150 },
    { subject: 'Pediatria', A: 86, fullMark: 150 },
    { subject: 'Gineco', A: 99, fullMark: 150 },
    { subject: 'Preventiva', A: 85, fullMark: 150 },
  ];

  const barData = [
    { name: 'Seg', hours: 4 },
    { name: 'Ter', hours: 3 },
    { name: 'Qua', hours: 5 },
    { name: 'Qui', hours: 2 },
    { name: 'Sex', hours: 6 },
    { name: 'Sáb', hours: 4 },
    { name: 'Dom', hours: 1 },
  ];

  return (
    <div className="space-y-6 pb-8 pt-2">
      <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Análises</h2>

      <div className="flex p-1 bg-gray-200 dark:bg-[#1F1F1F] rounded-xl">
         <button 
           onClick={() => setTab('subject')}
           className={`flex-1 py-2 text-sm font-bold rounded-lg transition-all ${tab === 'subject' ? 'bg-white dark:bg-[#333] text-black dark:text-white shadow-sm' : 'text-gray-500 dark:text-[#777]'}`}
         >
           Por Matéria
         </button>
         <button 
           onClick={() => setTab('time')}
           className={`flex-1 py-2 text-sm font-bold rounded-lg transition-all ${tab === 'time' ? 'bg-white dark:bg-[#333] text-black dark:text-white shadow-sm' : 'text-gray-500 dark:text-[#777]'}`}
         >
           Por Tempo
         </button>
      </div>
      
      {tab === 'subject' ? (
        <div className="space-y-6 animate-fade-in">
            {/* Level Section */}
            <div className="flex items-center gap-4">
                <div className="relative w-16 h-16 rounded-2xl bg-gradient-to-br from-[#D4A54A] to-[#8C6A28] flex items-center justify-center shadow-lg shadow-[#D4A54A]/20">
                    <span className="text-2xl font-black text-black z-10">{userStats.level}</span>
                    <Star className="absolute top-1 right-1 text-white/50" size={12} fill="currentColor" />
                </div>
                <div className="flex-1">
                    <h2 className="text-xl font-bold text-gray-900 dark:text-white">Residente Sênior</h2>
                    <div className="flex justify-between text-xs text-gray-500 dark:text-[#777] mb-1">
                    <span className="font-mono">{userStats.xp} XP</span>
                    <span className="font-mono">Próx: {userStats.level * XP_PER_LEVEL} XP</span>
                    </div>
                    <div className="w-full h-2 bg-gray-200 dark:bg-[#1F1F1F] rounded-full overflow-hidden">
                    <div 
                        className="h-full bg-[#D4A54A] shadow-[0_0_10px_rgba(212,165,74,0.5)]" 
                        style={{ width: `${Math.min(100, (userStats.xp / (userStats.level * XP_PER_LEVEL)) * 100)}%` }}
                    />
                    </div>
                </div>
            </div>

            {/* Radar Chart */}
            <div className="space-y-3">
                <h3 className="text-gray-900 dark:text-white font-bold text-lg">Competência Técnica</h3>
                <Card className="h-72 flex flex-col items-center justify-center relative bg-white dark:bg-gradient-to-b dark:from-[#0A0A0A] dark:to-[#050505]">
                <ResponsiveContainer width="100%" height="100%">
                    <RadarChart cx="50%" cy="50%" outerRadius="70%" data={radarData}>
                    <PolarGrid stroke="#333" />
                    <PolarAngleAxis dataKey="subject" tick={{ fill: '#A3A3A3', fontSize: 10 }} />
                    <Radar
                        name="Mike"
                        dataKey="A"
                        stroke="#D4A54A"
                        fill="#D4A54A"
                        fillOpacity={0.4}
                    />
                    </RadarChart>
                </ResponsiveContainer>
                </Card>
            </div>

            {/* Badges */}
            <div className="space-y-3">
                <h3 className="text-gray-900 dark:text-white font-bold text-lg flex items-center gap-2">
                <Trophy size={18} className="text-[#D4A54A]" />
                Conquistas
                </h3>
                <div className="grid grid-cols-4 gap-2">
                {BADGES.map((badge) => {
                    const isUnlocked = userStats.badges.includes(badge.id) || badge.unlocked;
                    const Icon = IconMap[badge.icon] || Trophy;
                    
                    return (
                    <div key={badge.id} className="flex flex-col items-center gap-2 group cursor-pointer">
                        <div className={`
                            w-14 h-14 rounded-full flex items-center justify-center border-2 transition-all duration-300
                            ${isUnlocked 
                            ? 'bg-[#D4A54A]/10 border-[#D4A54A] text-[#D4A54A] shadow-[0_0_10px_rgba(212,165,74,0.3)] group-hover:scale-105' 
                            : 'bg-gray-100 dark:bg-[#0A0A0A] border-gray-200 dark:border-[#1F1F1F] text-gray-300 dark:text-[#333] grayscale'}
                        `}>
                            {isUnlocked ? <Icon size={24} /> : <Lock size={20} />}
                        </div>
                    </div>
                    )
                })}
                </div>
            </div>
        </div>
      ) : (
        <div className="space-y-6 animate-fade-in">
            <Card className="h-64">
               <h3 className="text-sm font-bold text-gray-500 dark:text-[#777] mb-4">HORAS ESTUDADAS</h3>
               <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={barData}>
                        <XAxis dataKey="name" tick={{fill: '#888', fontSize: 10}} axisLine={false} tickLine={false} />
                        <Tooltip 
                           contentStyle={{backgroundColor: '#111', border: '1px solid #333', borderRadius: '8px', color: '#fff'}}
                           cursor={{fill: 'rgba(212,165,74,0.1)'}}
                        />
                        <Bar dataKey="hours" fill="#D4A54A" radius={[4, 4, 0, 0]} />
                    </BarChart>
               </ResponsiveContainer>
            </Card>

            <div className="grid grid-cols-2 gap-4">
                <Card className="p-4 bg-[#D4A54A]/10 border-[#D4A54A]/30">
                <div className="flex items-start justify-between mb-2">
                    <Trophy size={20} className="text-[#D4A54A]" />
                    <span className="text-xs text-[#D4A54A] font-bold">+12%</span>
                </div>
                <div className="text-2xl font-bold text-gray-900 dark:text-white">82%</div>
                <div className="text-[10px] text-gray-500 dark:text-[#A3A3A3]">Eficiência Global</div>
                </Card>
                
                <Card className="p-4">
                <div className="flex items-start justify-between mb-2">
                    <AlertTriangle size={20} className="text-red-500" />
                    <span className="text-xs text-red-500 font-bold">Atenção</span>
                </div>
                <div className="text-lg font-bold text-gray-900 dark:text-white leading-tight">Neonatologia</div>
                <div className="text-[10px] text-gray-500 dark:text-[#A3A3A3] mt-1">Tópico mais fraco</div>
                </Card>
            </div>
        </div>
      )}
    </div>
  );
};
