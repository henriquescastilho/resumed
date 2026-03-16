
import React, { useState, useEffect, useCallback } from 'react';
import { ViewState, UserProfile } from '../types';
import { Button, Input, Card } from '../components/Common';
import { Logo } from '../components/Logo';
import { SUBJECTS } from '../constants';
import { ChevronRight, Plus, Minus, Check } from 'lucide-react';

interface OnboardingProps {
  setView: (v: ViewState) => void;
  setProfile: (p: UserProfile) => void;
}

export const Onboarding: React.FC<OnboardingProps> = ({ setView, setProfile }) => {
  const [step, setStep] = useState<ViewState>('ONBOARDING_WELCOME');
  
  // Internal State
  const [name, setName] = useState('');
  const [exams, setExams] = useState<string[]>([]);
  const [days, setDays] = useState<string[]>(['1', '2', '3', '4', '5']);
  const [hours, setHours] = useState<Record<string, number>>({
    '0': 2, '1': 4, '2': 4, '3': 4, '4': 4, '5': 4, '6': 2
  });
  const [weights, setWeights] = useState<Record<string, 'pouco' | 'medio' | 'bastante'>>({});

  const nextStep = (next: ViewState) => setStep(next);

  const renderWelcome = () => (
    <div className="h-full flex flex-col items-center justify-center text-center space-y-12 animate-fade-in">
      <div className="relative">
        <div className="absolute inset-0 bg-[#D4A54A] blur-[80px] opacity-10 rounded-full"></div>
        <Logo size={120} className="relative z-10" />
      </div>
      <div className="space-y-4">
        <h1 className="text-4xl font-black tracking-tighter text-white">RESUMED</h1>
        <p className="text-[#A3A3A3] text-lg font-medium italic">“Estudar com método muda tudo.”</p>
      </div>
      <div className="w-full max-w-xs space-y-4">
        <Input 
          placeholder="Como devemos te chamar?" 
          value={name} 
          onChange={e => setName(e.target.value)}
          className="text-center"
        />
        <Button fullWidth onClick={() => nextStep('ONBOARDING_EXAMS')} disabled={!name}>
          Começar
        </Button>
      </div>
    </div>
  );

  const renderExams = () => (
    <div className="h-full flex flex-col space-y-8 animate-fade-in pt-12">
      <div className="space-y-2">
        <h2 className="text-2xl font-bold text-white">Quais provas você fará?</h2>
        <p className="text-[#777]">Selecione todas as que pretende prestar.</p>
      </div>
      <div className="flex-1 space-y-3">
        {['ENAMED', 'Revalida INEP', 'USP-SP', 'Unifesp', 'SUS-SP', 'Enafe'].map(exam => (
          <button
            key={exam}
            onClick={() => setExams(prev => prev.includes(exam) ? prev.filter(e => e !== exam) : [...prev, exam])}
            className={`w-full p-5 rounded-2xl border transition-all text-left flex justify-between items-center ${
              exams.includes(exam) ? 'bg-[#D4A54A]/10 border-[#D4A54A] text-white' : 'bg-[#0A0A0A] border-[#1F1F1F] text-[#777]'
            }`}
          >
            <span className="font-bold">{exam}</span>
            {exams.includes(exam) && <Check size={20} className="text-[#D4A54A]" />}
          </button>
        ))}
      </div>
      <Button fullWidth onClick={() => nextStep('ONBOARDING_DAYS')} disabled={exams.length === 0}>
        Continuar
      </Button>
    </div>
  );

  const renderDays = () => (
    <div className="h-full flex flex-col items-center justify-center space-y-12 animate-fade-in">
      <div className="text-center space-y-2">
        <h2 className="text-2xl font-bold text-white">Dias de Estudo</h2>
        <p className="text-[#777]">Em quais dias você terá foco total?</p>
      </div>
      
      <div className="flex justify-center items-center gap-3">
        {['D', 'S', 'T', 'Q', 'Q', 'S', 'S'].map((day, i) => {
          const isSelected = days.includes(i.toString());
          return (
            <button
              key={i}
              onClick={() => setDays(prev => prev.includes(i.toString()) ? prev.filter(d => d !== i.toString()) : [...prev, i.toString()])}
              className={`w-12 h-12 rounded-full border-2 flex items-center justify-center font-bold transition-all ${
                isSelected ? 'bg-[#D4A54A] border-[#D4A54A] text-black shadow-lg shadow-[#D4A54A]/20 scale-110' : 'bg-transparent border-[#1F1F1F] text-[#555]'
              }`}
            >
              {day}
            </button>
          );
        })}
      </div>

      <Button className="w-full max-w-xs" onClick={() => nextStep('ONBOARDING_HOURS')}>
        Definir Horas
      </Button>
    </div>
  );

  const renderHours = () => (
    <div className="h-full flex flex-col space-y-8 animate-fade-in pt-12">
      <div className="space-y-2 text-center">
        <h2 className="text-2xl font-bold text-white">Ritmo Diário</h2>
        <p className="text-[#777]">Quantas horas em média por dia?</p>
      </div>
      
      <div className="grid grid-cols-3 gap-4">
        {[1, 2, 3, 4, 6, 8, 10, 12].map(h => (
          <button
            key={h}
            onClick={() => {
              const newHours = { ...hours };
              days.forEach(d => newHours[d] = h);
              setHours(newHours);
              nextStep('ONBOARDING_DISTRIBUTION');
            }}
            className="aspect-square rounded-2xl border border-[#1F1F1F] bg-[#0A0A0A] flex flex-col items-center justify-center hover:border-[#D4A54A] group"
          >
            <span className="text-2xl font-bold text-white group-hover:text-[#D4A54A]">{h}h</span>
          </button>
        ))}
      </div>
    </div>
  );

  const renderDistribution = () => (
    <div className="h-full flex flex-col space-y-8 animate-fade-in pt-12 pb-6">
      <div className="space-y-2">
        <h2 className="text-2xl font-bold text-white">Ajuste Fino</h2>
        <p className="text-[#777]">Personalize sua carga horária por dia.</p>
      </div>

      <div className="flex-1 space-y-3 overflow-y-auto no-scrollbar">
        {['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'].map((name, i) => {
          if (!days.includes(i.toString())) return null;
          return (
            <div key={i} className="flex items-center justify-between p-4 bg-[#0A0A0A] border border-[#1F1F1F] rounded-2xl">
              <span className="font-bold text-white">{name}</span>
              <div className="flex items-center gap-4">
                <button onClick={() => setHours({...hours, [i]: Math.max(0.5, hours[i.toString()] - 0.5)})} className="p-2 bg-[#1F1F1F] rounded-lg text-[#D4A54A]"><Minus size={16} /></button>
                <span className="w-12 text-center font-bold text-[#D4A54A]">{hours[i.toString()]}h</span>
                <button onClick={() => setHours({...hours, [i]: hours[i.toString()] + 0.5})} className="p-2 bg-[#1F1F1F] rounded-lg text-[#D4A54A]"><Plus size={16} /></button>
              </div>
            </div>
          );
        })}
      </div>

      <Button fullWidth onClick={() => nextStep('ONBOARDING_ASSESSMENT')}>Próximo</Button>
    </div>
  );

  const renderAssessment = () => (
    <div className="h-full flex flex-col space-y-8 animate-fade-in pt-12 pb-6">
      <div className="space-y-2">
        <h2 className="text-2xl font-bold text-white">Autoavaliação</h2>
        <p className="text-[#777]">Como está seu conhecimento em cada área?</p>
      </div>

      <div className="flex-1 space-y-6 overflow-y-auto no-scrollbar">
        {SUBJECTS.map(subj => (
          <div key={subj} className="space-y-3">
            <p className="text-sm font-bold text-white ml-1">{subj}</p>
            <div className="grid grid-cols-3 gap-2">
              {['pouco', 'medio', 'bastante'].map(level => (
                <button
                  key={level}
                  onClick={() => setWeights({...weights, [subj]: level as any})}
                  className={`py-3 rounded-xl border text-xs font-bold uppercase tracking-widest transition-all ${
                    weights[subj] === level ? 'bg-[#D4A54A] text-black border-[#D4A54A]' : 'bg-[#0A0A0A] border-[#1F1F1F] text-[#555]'
                  }`}
                >
                  {level}
                </button>
              ))}
            </div>
          </div>
        ))}
      </div>

      <Button fullWidth onClick={() => nextStep('ONBOARDING_PROCESSING')}>Finalizar Configuração</Button>
    </div>
  );

  const handleProcessingComplete = useCallback(() => {
    setProfile({
      name,
      targetExams: exams,
      availableDays: days,
      hoursPerDay: hours,
      subjectWeights: weights
    });
    setView('HOME');
  }, [name, exams, days, hours, weights, setProfile, setView]);

  const ProcessingStep: React.FC = () => {
    useEffect(() => {
      const timer = setTimeout(handleProcessingComplete, 4000);
      return () => clearTimeout(timer);
    }, []);

    return (
      <div className="h-full flex flex-col items-center justify-center text-center space-y-8 animate-fade-in">
        <div className="relative">
          <div className="absolute inset-0 bg-[#D4A54A] blur-[60px] opacity-20 animate-pulse"></div>
          <Logo size={100} className="relative z-10 animate-spin-slow" />
        </div>
        <div className="space-y-2">
          <h2 className="text-2xl font-bold text-white">Montando seu plano...</h2>
          <p className="text-[#D4A54A] font-mono text-sm">Otimizando sua curva de aprendizado</p>
        </div>
        <div className="w-full max-w-xs h-1 bg-[#1F1F1F] rounded-full overflow-hidden">
          <div className="h-full bg-[#D4A54A] animate-[width_4s_ease-in-out]"></div>
        </div>
      </div>
    );
  };

  switch (step) {
    case 'ONBOARDING_WELCOME': return renderWelcome();
    case 'ONBOARDING_EXAMS': return renderExams();
    case 'ONBOARDING_DAYS': return renderDays();
    case 'ONBOARDING_HOURS': return renderHours();
    case 'ONBOARDING_DISTRIBUTION': return renderDistribution();
    case 'ONBOARDING_ASSESSMENT': return renderAssessment();
    case 'ONBOARDING_PROCESSING': return <ProcessingStep />;
    default: return renderWelcome();
  }
};
