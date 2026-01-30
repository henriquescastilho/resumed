
import React from 'react';
import { Card } from '../components/Common';
import { CalendarDays, Target, GraduationCap, Clock, Award, ChevronRight, Edit3 } from 'lucide-react';
import { MOCK_TASKS } from '../constants';

export const Plan: React.FC = () => {
  // This data would typically come from the global UserProfile state
  const userProfile = {
    name: "Dr. Silva",
    stage: "Internato (6º Ano)",
    exam: "ENAMED 2024",
    specialty: "Cardiologia",
    hours: 4,
    focusAreas: ["Cardiologia", "Pneumologia", "Emergências"],
    weakAreas: ["Ginecologia", "Pediatria"]
  };

  return (
    <div className="space-y-8 pt-2 pb-10">
      
      {/* 1. HEADER PROFILE */}
      <div className="relative overflow-hidden rounded-3xl bg-black border border-[#1F1F1F]">
         <div className="absolute top-0 right-0 w-64 h-64 bg-[#D4A54A] blur-[100px] opacity-20"></div>
         
         <div className="relative p-6 md:p-8 flex flex-col md:flex-row md:items-center gap-6">
            <div className="w-20 h-20 rounded-full border-2 border-[#D4A54A] p-1">
               <div className="w-full h-full rounded-full bg-[#1F1F1F] flex items-center justify-center text-2xl font-bold text-[#D4A54A]">
                  DS
               </div>
            </div>
            
            <div className="flex-1 space-y-2">
               <div className="flex items-center gap-3">
                  <h2 className="text-2xl font-bold text-white">{userProfile.name}</h2>
                  <span className="px-2 py-1 bg-[#D4A54A] text-black text-[10px] font-bold rounded uppercase">
                     PRO
                  </span>
               </div>
               <p className="text-gray-400 text-sm flex items-center gap-2">
                  <GraduationCap size={16} />
                  {userProfile.stage}
               </p>
               <div className="flex items-center gap-4 pt-2">
                  <div className="flex items-center gap-1.5 text-sm text-[#D4A54A]">
                     <Target size={16} />
                     <span className="font-bold">{userProfile.exam}</span>
                  </div>
                  <div className="w-1 h-1 rounded-full bg-gray-600"></div>
                  <div className="text-sm text-white">
                     Foco: <span className="font-bold">{userProfile.specialty}</span>
                  </div>
               </div>
            </div>

            <button className="p-3 bg-[#1F1F1F] rounded-xl hover:bg-[#333] transition-colors border border-[#333]">
               <Edit3 size={20} className="text-gray-400" />
            </button>
         </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
         
         {/* 2. STRATEGY SUMMARY */}
         <div className="space-y-4">
            <h3 className="text-lg font-bold text-gray-900 dark:text-white flex items-center gap-2">
               <Award size={20} className="text-[#D4A54A]" />
               Estratégia Vigente
            </h3>
            
            <div className="space-y-3">
               <Card className="flex items-center justify-between p-4 group cursor-pointer hover:border-[#D4A54A]">
                  <div className="flex items-center gap-4">
                     <div className="w-10 h-10 rounded-lg bg-green-500/10 text-green-500 flex items-center justify-center">
                        <Target size={20} />
                     </div>
                     <div>
                        <p className="text-xs text-gray-500 dark:text-[#777] uppercase font-bold">Pontos Fortes</p>
                        <p className="text-sm font-medium text-gray-900 dark:text-white">
                           {userProfile.focusAreas.join(', ')}
                        </p>
                     </div>
                  </div>
               </Card>

               <Card className="flex items-center justify-between p-4 group cursor-pointer hover:border-[#D4A54A]">
                  <div className="flex items-center gap-4">
                     <div className="w-10 h-10 rounded-lg bg-red-500/10 text-red-500 flex items-center justify-center">
                        <Target size={20} />
                     </div>
                     <div>
                        <p className="text-xs text-gray-500 dark:text-[#777] uppercase font-bold">Atenção Prioritária</p>
                        <p className="text-sm font-medium text-gray-900 dark:text-white">
                           {userProfile.weakAreas.join(', ')}
                        </p>
                     </div>
                  </div>
               </Card>

               <Card className="flex items-center justify-between p-4 group cursor-pointer hover:border-[#D4A54A]">
                  <div className="flex items-center gap-4">
                     <div className="w-10 h-10 rounded-lg bg-[#D4A54A]/10 text-[#D4A54A] flex items-center justify-center">
                        <Clock size={20} />
                     </div>
                     <div>
                        <p className="text-xs text-gray-500 dark:text-[#777] uppercase font-bold">Carga Horária</p>
                        <p className="text-sm font-medium text-gray-900 dark:text-white">
                           {userProfile.hours} horas / dia
                        </p>
                     </div>
                  </div>
               </Card>
            </div>
         </div>

         {/* 3. MACRO SCHEDULE */}
         <div className="space-y-4">
             <div className="flex items-center justify-between">
                <h3 className="text-lg font-bold text-gray-900 dark:text-white flex items-center gap-2">
                    <CalendarDays size={20} className="text-[#D4A54A]" />
                    Visão Macro
                </h3>
                <button className="text-xs font-bold text-[#D4A54A]">EDITAR</button>
             </div>

             <div className="bg-white dark:bg-[#0A0A0A] border border-gray-200 dark:border-[#1F1F1F] rounded-2xl p-4 space-y-4">
                 {['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'].map((day, i) => (
                    <div key={day} className="flex items-center gap-4">
                       <div className="w-16 text-xs font-bold text-gray-500 dark:text-[#777]">{day}</div>
                       <div className="flex-1 h-2 bg-gray-100 dark:bg-[#1F1F1F] rounded-full overflow-hidden">
                          <div 
                             className="h-full bg-[#D4A54A] opacity-80" 
                             style={{width: `${Math.random() * 60 + 20}%`}}
                          ></div>
                       </div>
                       <div className="text-[10px] text-gray-400 font-mono">{4 + (i%2)}h</div>
                    </div>
                 ))}
             </div>
         </div>

      </div>
    </div>
  );
};
