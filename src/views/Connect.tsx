
import React from 'react';
import { Card, Button, Input } from '../components/Common';
import { MOCK_PEER_QUESTIONS } from '../constants';
import { Users, MessageCircle, Heart, Search, Filter } from 'lucide-react';

export const Connect: React.FC = () => {
  return (
    <div className="space-y-6 pt-2 pb-20">
      <div className="flex items-center justify-between">
        <div>
           <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Comunidade Resumed</h2>
           <p className="text-sm text-gray-500 dark:text-[#777]">Tire dúvidas com residentes e estudantes.</p>
        </div>
        <Button className="px-4 py-2 h-auto text-sm gap-2 flex items-center">
            <Users size={16} />
            <span>Criar Grupo</span>
        </Button>
      </div>

      {/* Search & Filter */}
      <div className="flex gap-3">
         <div className="flex-1 relative">
            <input 
              placeholder="Buscar dúvidas (ex: ECG, Pediatria)..." 
              className="w-full bg-white dark:bg-[#111] border border-gray-200 dark:border-[#333] rounded-xl pl-10 pr-4 py-3 text-sm focus:border-[#D4A54A] focus:outline-none"
            />
            <Search className="absolute left-3 top-3 text-gray-400" size={18} />
         </div>
         <button className="p-3 bg-white dark:bg-[#111] border border-gray-200 dark:border-[#333] rounded-xl hover:border-[#D4A54A]">
            <Filter size={18} className="text-gray-500 dark:text-[#A3A3A3]" />
         </button>
      </div>

      {/* Topics List */}
      <div className="space-y-4">
         <h3 className="text-sm font-bold text-gray-500 dark:text-[#777] uppercase tracking-wider">Discussões Recentes</h3>
         
         {MOCK_PEER_QUESTIONS.map((q) => (
             <Card key={q.id} className="hover:border-[#D4A54A]/50 cursor-pointer transition-colors group">
                <div className="flex justify-between items-start mb-2">
                   <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-full bg-gray-200 dark:bg-[#222] flex items-center justify-center text-xs font-bold text-[#777]">
                         {q.author.charAt(0)}
                      </div>
                      <div>
                         <p className="text-xs font-bold text-gray-900 dark:text-white">{q.author}</p>
                         <p className="text-[10px] text-gray-500">{q.specialty} • {q.timeAgo} atrás</p>
                      </div>
                   </div>
                   <span className="bg-[#D4A54A]/10 text-[#D4A54A] text-[10px] font-bold px-2 py-1 rounded">
                      {q.specialty.toUpperCase()}
                   </span>
                </div>
                
                <p className="text-sm text-gray-800 dark:text-gray-200 leading-relaxed mb-4">
                   {q.text}
                </p>

                <div className="flex items-center gap-4 border-t border-gray-100 dark:border-[#1F1F1F] pt-3">
                   <button className="flex items-center gap-1.5 text-xs text-gray-500 hover:text-[#D4A54A] transition-colors">
                      <MessageCircle size={16} />
                      <span className="font-medium">{q.responses} respostas</span>
                   </button>
                   <button className="flex items-center gap-1.5 text-xs text-gray-500 hover:text-red-500 transition-colors">
                      <Heart size={16} />
                      <span>Curtir</span>
                   </button>
                   <div className="flex-1 text-right">
                      <span className="text-xs font-bold text-[#D4A54A] opacity-0 group-hover:opacity-100 transition-opacity">
                         Responder
                      </span>
                   </div>
                </div>
             </Card>
         ))}
      </div>
    </div>
  );
};
