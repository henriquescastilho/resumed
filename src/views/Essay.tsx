
import React, { useState } from 'react';
import { ViewState } from '../types';
import { Button, Card } from '../components/Common';
import { MOCK_ESSAY_TOPICS } from '../constants';
import { ChevronLeft, PenTool, Send, AlertCircle, FileText } from 'lucide-react';

export const Essay: React.FC<{ setView: (v: ViewState) => void }> = ({ setView }) => {
  const [selectedTopic, setSelectedTopic] = useState<string | null>(null);
  const [essayText, setEssayText] = useState('');

  const currentTopic = MOCK_ESSAY_TOPICS.find(t => t.id === selectedTopic);

  if (selectedTopic && currentTopic) {
    // Editor Mode
    return (
      <div className="h-full flex flex-col pt-2">
        <div className="flex items-center gap-2 mb-4">
           <button onClick={() => setSelectedTopic(null)} className="p-2 hover:bg-gray-100 dark:hover:bg-[#1F1F1F] rounded-full text-gray-500 dark:text-[#A3A3A3]">
              <ChevronLeft size={24} />
           </button>
           <h2 className="text-lg font-bold text-gray-900 dark:text-white truncate">Redação</h2>
        </div>

        <Card className="mb-4 bg-yellow-50 dark:bg-yellow-900/10 border-yellow-200 dark:border-yellow-700/30">
           <div className="flex gap-3">
              <AlertCircle size={20} className="text-[#D4A54A] flex-shrink-0 mt-0.5" />
              <div>
                 <h4 className="text-sm font-bold text-[#D4A54A]">Tema</h4>
                 <p className="text-sm text-gray-800 dark:text-gray-200 leading-relaxed mt-1">{currentTopic.title}</p>
              </div>
           </div>
        </Card>

        <div className="flex-1 relative">
           <textarea 
             className="w-full h-full bg-white dark:bg-[#0A0A0A] border border-gray-200 dark:border-[#333] rounded-xl p-4 text-gray-800 dark:text-gray-200 resize-none focus:outline-none focus:border-[#D4A54A]"
             placeholder="Comece a escrever sua redação aqui..."
             value={essayText}
             onChange={(e) => setEssayText(e.target.value)}
           />
           <div className="absolute bottom-4 right-4 text-xs text-gray-400 bg-white dark:bg-black px-2 py-1 rounded border border-gray-200 dark:border-[#333]">
              {essayText.length} caracteres
           </div>
        </div>

        <div className="pt-4">
           <Button fullWidth className="flex items-center justify-center gap-2">
              <Send size={18} />
              Enviar para Correção (IA)
           </Button>
        </div>
      </div>
    );
  }

  // Topic List Mode
  return (
    <div className="space-y-6 pt-4">
      <div className="flex items-center justify-between">
         <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Redação</h2>
         <PenTool className="text-[#D4A54A]" />
      </div>

      <div className="space-y-4">
         <h3 className="text-sm font-bold text-gray-500 dark:text-[#777] uppercase tracking-wider">Propostas de Redação</h3>
         
         {MOCK_ESSAY_TOPICS.map((topic) => (
            <button 
              key={topic.id}
              onClick={() => setSelectedTopic(topic.id)}
              className="w-full text-left group"
            >
              <Card className="hover:border-[#D4A54A] transition-colors group-active:scale-[0.99]">
                 <div className="flex justify-between items-start">
                    <div className="flex-1 mr-4">
                       <span className="text-[10px] font-bold text-[#D4A54A] bg-[#D4A54A]/10 px-2 py-0.5 rounded-full mb-2 inline-block">
                         {topic.source}
                       </span>
                       <h4 className="text-sm font-medium text-gray-900 dark:text-white leading-snug">
                         {topic.title}
                       </h4>
                    </div>
                    <div className="text-gray-300 dark:text-[#333] group-hover:text-[#D4A54A]">
                       <FileText size={20} />
                    </div>
                 </div>
              </Card>
            </button>
         ))}
      </div>

      <div className="pt-4">
         <Button variant="outline" fullWidth>Ver histórico de correções</Button>
      </div>
    </div>
  );
};
