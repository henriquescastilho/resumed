
import React, { useState } from 'react';
import { ViewState } from '../types';
import { Button, Card } from '../components/Common';
import { ChevronLeft, Layers, BookOpen, Clock, CheckCircle2 } from 'lucide-react';

export const Practice: React.FC<{ setView: (v: ViewState) => void }> = ({ setView }) => {
  const [step, setStep] = useState<'menu' | 'config' | 'session'>('menu');
  
  // Config State
  const [mode, setMode] = useState<'bank' | 'exam' | 'custom'>('bank');
  
  if (step === 'menu') {
    return (
      <div className="space-y-6 pt-4">
        <div className="flex items-center gap-2">
           <button onClick={() => setView('HOME')} className="p-2 hover:bg-gray-100 dark:hover:bg-[#1F1F1F] rounded-full text-gray-500 dark:text-[#A3A3A3]">
              <ChevronLeft size={24} />
           </button>
           <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Praticar</h2>
        </div>

        <div className="grid grid-cols-1 gap-4">
           <Card className="cursor-pointer hover:border-[#D4A54A]" onClick={() => { setMode('bank'); setStep('config'); }}>
              <div className="flex items-center gap-4">
                 <div className="w-12 h-12 rounded-full bg-blue-500/10 text-blue-500 flex items-center justify-center">
                    <Layers size={24} />
                 </div>
                 <div>
                    <h3 className="font-bold text-gray-900 dark:text-white">Banco de Questões</h3>
                    <p className="text-xs text-gray-500 dark:text-[#777]">Milhares de questões filtradas</p>
                 </div>
              </div>
           </Card>

           <Card className="cursor-pointer hover:border-[#D4A54A]" onClick={() => { setMode('exam'); setStep('config'); }}>
              <div className="flex items-center gap-4">
                 <div className="w-12 h-12 rounded-full bg-purple-500/10 text-purple-500 flex items-center justify-center">
                    <BookOpen size={24} />
                 </div>
                 <div>
                    <h3 className="font-bold text-gray-900 dark:text-white">Provas Anteriores</h3>
                    <p className="text-xs text-gray-500 dark:text-[#777]">Simule condições reais de prova</p>
                 </div>
              </div>
           </Card>

           <Card className="cursor-pointer hover:border-[#D4A54A]" onClick={() => setView('RESUCARDS')}>
              <div className="flex items-center gap-4">
                 <div className="w-12 h-12 rounded-full bg-[#D4A54A]/10 text-[#D4A54A] flex items-center justify-center">
                    <Clock size={24} />
                 </div>
                 <div>
                    <h3 className="font-bold text-gray-900 dark:text-white">ResuCards (SRS)</h3>
                    <p className="text-xs text-gray-500 dark:text-[#777]">Revisão espaçada inteligente</p>
                 </div>
              </div>
           </Card>
        </div>
      </div>
    );
  }

  if (step === 'config') {
    return (
      <div className="space-y-6 pt-4 h-full flex flex-col">
        <div className="flex items-center gap-2">
           <button onClick={() => setStep('menu')} className="p-2 hover:bg-gray-100 dark:hover:bg-[#1F1F1F] rounded-full text-gray-500 dark:text-[#A3A3A3]">
              <ChevronLeft size={24} />
           </button>
           <h2 className="text-xl font-bold text-gray-900 dark:text-white">Configurar Sessão</h2>
        </div>

        <div className="flex-1 space-y-6">
           <div className="space-y-3">
              <label className="text-sm font-bold text-gray-500 dark:text-[#777]">DISCIPLINAS</label>
              <div className="grid grid-cols-2 gap-2">
                 {['Cardiologia', 'Pediatria', 'Cirurgia', 'Ginecologia', 'Preventiva', 'Infecto'].map(d => (
                    <button key={d} className="p-3 rounded-xl border border-gray-200 dark:border-[#333] text-sm text-gray-600 dark:text-[#A3A3A3] hover:border-[#D4A54A] hover:text-[#D4A54A] transition-colors text-left">
                       {d}
                    </button>
                 ))}
              </div>
           </div>

           <div className="space-y-3">
              <label className="text-sm font-bold text-gray-500 dark:text-[#777]">QUANTIDADE</label>
              <div className="flex gap-4">
                 {[10, 20, 50].map(q => (
                    <button key={q} className="flex-1 p-3 rounded-xl border border-gray-200 dark:border-[#333] text-gray-900 dark:text-white font-bold hover:bg-[#D4A54A] hover:text-black hover:border-[#D4A54A] transition-colors">
                       {q}
                    </button>
                 ))}
              </div>
           </div>
        </div>

        <Button fullWidth onClick={() => setStep('session')}>Começar Agora</Button>
      </div>
    );
  }

  // Session Mock
  return (
    <div className="h-full flex flex-col pt-4 pb-8">
       <div className="flex justify-between items-center mb-6">
          <button onClick={() => setStep('menu')} className="text-sm text-gray-500 dark:text-[#777]">Encerrar</button>
          <span className="font-mono font-bold text-[#D4A54A]">04:59</span>
          <span className="text-sm text-gray-900 dark:text-white font-bold">1/10</span>
       </div>

       <div className="flex-1 overflow-y-auto">
          <p className="text-xs text-gray-500 dark:text-[#777] uppercase tracking-wider mb-2">Clínica Médica • Cardiologia</p>
          <h3 className="text-lg font-medium text-gray-900 dark:text-white leading-relaxed mb-6">
             Um paciente de 65 anos chega ao pronto-socorro com dispneia progressiva e edema de membros inferiores. Ao exame físico, apresenta turgência jugular patológica e hepatomegalia dolorosa. Qual o diagnóstico mais provável?
          </h3>
          
          <div className="space-y-3">
             {['Insuficiência Cardíaca Esquerda', 'Insuficiência Cardíaca Direita', 'Tromboembolismo Pulmonar', 'Cirrose Hepática'].map((opt, i) => (
                <button key={i} className="w-full p-4 rounded-xl border border-gray-200 dark:border-[#333] text-left text-gray-700 dark:text-[#CCC] hover:border-[#D4A54A] hover:bg-[#D4A54A]/5 transition-colors">
                   <span className="font-bold mr-3 text-gray-400 dark:text-[#555]">{String.fromCharCode(65 + i)}</span>
                   {opt}
                </button>
             ))}
          </div>
       </div>

       <Button fullWidth className="mt-4">Responder</Button>
    </div>
  );
};
