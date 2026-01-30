
import React, { useState } from 'react';
import { Card } from '../components/Common';
import { MOCK_HISTORY } from '../constants';
import { FileText, CheckCircle2, BookOpen } from 'lucide-react';

export const History: React.FC = () => {
  const [filter, setFilter] = useState<'all' | 'exam' | 'exercise' | 'essay'>('all');

  const filteredHistory = MOCK_HISTORY.filter(h => filter === 'all' || h.type === filter);

  const getIcon = (type: string) => {
    switch (type) {
        case 'exam': return <BookOpen size={18} />;
        case 'essay': return <FileText size={18} />;
        default: return <CheckCircle2 size={18} />;
    }
  };

  const getLabel = (type: string) => {
    switch (type) {
        case 'exam': return 'Simulado';
        case 'essay': return 'Redação';
        default: return 'Exercício';
    }
  };

  return (
    <div className="space-y-6 pt-2 pb-8">
      <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Histórico</h2>

      {/* Filter Chips */}
      <div className="flex gap-2 overflow-x-auto no-scrollbar pb-2">
         {['all', 'exam', 'exercise', 'essay'].map((f) => (
             <button
               key={f}
               onClick={() => setFilter(f as any)}
               className={`
                 px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-colors
                 ${filter === f 
                    ? 'bg-[#D4A54A] text-white dark:text-black' 
                    : 'bg-gray-200 dark:bg-[#1F1F1F] text-gray-500 dark:text-[#A3A3A3] hover:bg-gray-300 dark:hover:bg-[#333]'}
               `}
             >
                {f === 'all' ? 'Tudo' : f === 'essay' ? 'Redações' : f === 'exam' ? 'Provas' : 'Exercícios'}
             </button>
         ))}
      </div>

      <div className="space-y-3">
         {filteredHistory.length > 0 ? (
             filteredHistory.map((item) => (
                 <Card key={item.id} className="flex justify-between items-center p-4">
                     <div className="flex items-center gap-4">
                         <div className={`
                            w-10 h-10 rounded-full flex items-center justify-center
                            ${item.type === 'essay' ? 'bg-purple-500/10 text-purple-500' : item.type === 'exam' ? 'bg-orange-500/10 text-orange-500' : 'bg-blue-500/10 text-blue-500'}
                         `}>
                             {getIcon(item.type)}
                         </div>
                         <div>
                             <p className="text-[10px] font-bold text-gray-400 dark:text-[#555] uppercase tracking-wider mb-0.5">
                                 {getLabel(item.type)} • {new Date(item.date).toLocaleDateString()}
                             </p>
                             <h4 className="text-sm font-bold text-gray-900 dark:text-white">{item.title}</h4>
                         </div>
                     </div>
                     <div className="text-right">
                         <span className="block text-lg font-bold text-[#D4A54A]">{item.result}</span>
                     </div>
                 </Card>
             ))
         ) : (
             <div className="text-center py-10 text-gray-400 dark:text-[#555]">
                 Nenhum item encontrado.
             </div>
         )}
      </div>
    </div>
  );
};
