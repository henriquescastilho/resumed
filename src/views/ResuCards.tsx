
import React, { useState, useEffect } from 'react';
import { Flashcard } from '../types';
import { Button, Card } from '../components/Common';
import { RotateCcw, BrainCircuit, Clock } from 'lucide-react';

interface ResuCardsProps {
  flashcards: Flashcard[];
  onReview: (id: string, rating: 'fail' | 'hard' | 'good' | 'easy') => void;
}

export const ResuCards: React.FC<ResuCardsProps> = ({ flashcards, onReview }) => {
  // Filter for due cards
  const [queue, setQueue] = useState<Flashcard[]>([]);
  const [isFlipped, setIsFlipped] = useState(false);
  const [complete, setComplete] = useState(false);

  useEffect(() => {
    const now = new Date();
    const due = flashcards.filter(c => {
      // If never reviewed, or next review is in past
      if (!c.nextReview) return true;
      return new Date(c.nextReview) <= now;
    });
    setQueue(due);
  }, [flashcards]);

  const currentCard = queue[0];

  const handleRate = (rating: 'fail' | 'hard' | 'good' | 'easy') => {
    if (!currentCard) return;
    
    // Call parent handler
    onReview(currentCard.id, rating);
    
    // Animate transition
    setIsFlipped(false);
    setTimeout(() => {
      // Remove current from queue
      const nextQueue = queue.slice(1);
      setQueue(nextQueue);
      if (nextQueue.length === 0) setComplete(true);
    }, 200);
  };

  if (complete || !currentCard) {
    return (
      <div className="h-full flex flex-col items-center justify-center text-center space-y-6 animate-fade-in">
        <div className="w-24 h-24 rounded-full bg-[#D4A54A]/10 flex items-center justify-center border border-[#D4A54A]">
           <BrainCircuit size={48} className="text-[#D4A54A]" />
        </div>
        <div className="space-y-2">
          <h2 className="text-2xl font-bold text-white">Revisão Concluída!</h2>
          <p className="text-[#A3A3A3] max-w-xs mx-auto">
            O algoritmo SRS agendou seus próximos estudos. Volte amanhã para manter o ritmo.
          </p>
        </div>
        <div className="grid grid-cols-2 gap-4 w-full px-8">
           <Card className="flex flex-col items-center p-3 bg-[#111]">
              <span className="text-[#D4A54A] font-bold text-xl">+50 XP</span>
              <span className="text-[10px] text-[#555]">Bônus de Sessão</span>
           </Card>
           <Card className="flex flex-col items-center p-3 bg-[#111]">
              <span className="text-white font-bold text-xl">100%</span>
              <span className="text-[10px] text-[#555]">Foco</span>
           </Card>
        </div>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col items-center pt-4 pb-8">
      <div className="w-full flex justify-between items-center mb-6 px-2">
        <div className="flex items-center gap-2">
           <Clock size={14} className="text-[#D4A54A]" />
           <span className="text-xs text-[#A3A3A3] font-mono">SRS ATIVO</span>
        </div>
        <span className="text-[#A3A3A3] text-xs font-medium bg-[#1F1F1F] px-3 py-1 rounded-full">
          {queue.length} restantes
        </span>
      </div>

      <div className="flex-1 w-full flex items-center justify-center perspective-1000 group">
        <div 
          className={`
            relative w-full aspect-[3/4] max-h-[450px] transition-transform duration-500 preserve-3d cursor-pointer
            ${isFlipped ? 'rotate-y-180' : ''}
          `}
          onClick={() => !isFlipped && setIsFlipped(true)}
        >
          {/* Front */}
          <div className="absolute inset-0 backface-hidden bg-[#0A0A0A] border border-[#333] hover:border-[#D4A54A]/50 rounded-3xl p-8 flex flex-col items-center justify-center text-center shadow-2xl transition-colors">
            <span className="text-[#D4A54A] text-xs font-bold tracking-widest uppercase mb-4 opacity-50">Pergunta</span>
            <h3 className="text-xl md:text-2xl font-medium text-white leading-relaxed">{currentCard.front}</h3>
            <div className="absolute bottom-8 flex flex-col items-center gap-2">
               <span className="text-[#555] text-xs uppercase tracking-widest animate-pulse">Toque para ver a resposta</span>
            </div>
          </div>

          {/* Back */}
          <div className="absolute inset-0 backface-hidden rotate-y-180 bg-[#111] border border-[#D4A54A] rounded-3xl p-8 flex flex-col items-center justify-center text-center shadow-[0_0_50px_rgba(212,165,74,0.15)]">
            <span className="text-[#D4A54A] text-xs font-bold tracking-widest uppercase mb-4">Resposta</span>
            <h3 className="text-xl font-semibold text-white leading-relaxed">{currentCard.back}</h3>
          </div>
        </div>
      </div>

      {isFlipped ? (
        <div className="w-full mt-8 animate-fade-in space-y-3">
          <p className="text-center text-[#555] text-xs uppercase tracking-widest mb-2">Como foi?</p>
          <div className="grid grid-cols-4 gap-2">
            <button onClick={() => handleRate('fail')} className="flex flex-col items-center gap-1 p-3 rounded-xl bg-[#1F1F1F] border border-[#333] hover:border-red-500 hover:text-red-500 transition-all active:scale-95">
              <span className="text-sm font-bold">Errei</span>
              <span className="text-[10px] opacity-60">1d</span>
            </button>
            <button onClick={() => handleRate('hard')} className="flex flex-col items-center gap-1 p-3 rounded-xl bg-[#1F1F1F] border border-[#333] hover:border-orange-500 hover:text-orange-500 transition-all active:scale-95">
              <span className="text-sm font-bold">Difícil</span>
              <span className="text-[10px] opacity-60">2d</span>
            </button>
            <button onClick={() => handleRate('good')} className="flex flex-col items-center gap-1 p-3 rounded-xl bg-[#1F1F1F] border border-[#333] hover:border-[#D4A54A] hover:text-[#D4A54A] transition-all active:scale-95">
              <span className="text-sm font-bold">Bom</span>
              <span className="text-[10px] opacity-60">5d</span>
            </button>
            <button onClick={() => handleRate('easy')} className="flex flex-col items-center gap-1 p-3 rounded-xl bg-[#1F1F1F] border border-[#333] hover:border-green-500 hover:text-green-500 transition-all active:scale-95">
              <span className="text-sm font-bold">Fácil</span>
              <span className="text-[10px] opacity-60">8d</span>
            </button>
          </div>
        </div>
      ) : (
        <div className="h-[108px] flex items-end pb-4">
           {/* Placeholder space to prevent jump */}
           <div className="flex items-center gap-2 text-[#333]">
              <RotateCcw size={16} />
              <span className="text-xs">Vire o card para avaliar</span>
           </div>
        </div>
      )}
    </div>
  );
};
