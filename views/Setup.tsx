
import React, { useState, useEffect } from 'react';
import { ViewState } from '../types';
import { Button, Card, Input } from '../components/Common';
import { Logo } from '../components/Logo';
import { 
  Check, 
  ChevronRight, 
  Clock, 
  GraduationCap, 
  Stethoscope, 
  BrainCircuit, 
  Calendar,
  User,
  Activity
} from 'lucide-react';

export const Setup: React.FC<{ setView: (v: ViewState) => void }> = ({ setView }) => {
  const [step, setStep] = useState(1);
  const [isCalibrating, setIsCalibrating] = useState(false);
  const [calibrationText, setCalibrationText] = useState("Inicializando Grey...");

  // Form State
  const [formData, setFormData] = useState({
    name: '',
    stage: '', // 5º ano, 6º ano, Formado
    exam: '',
    specialty: '',
    days: [] as string[],
    hoursPerDay: 4
  });

  const totalSteps = 4;

  const handleNext = () => {
    if (step < totalSteps) {
      setStep(step + 1);
    } else {
      startCalibration();
    }
  };

  const startCalibration = () => {
    setIsCalibrating(true);
    const messages = [
      "Analisando edital do ENAMED...",
      `Mapeando competências para ${formData.specialty || 'sua especialidade'}...`,
      "Calculando curva de esquecimento...",
      "Gerando cronograma personalizado..."
    ];

    let i = 0;
    const interval = setInterval(() => {
      setCalibrationText(messages[i]);
      i++;
      if (i >= messages.length) {
        clearInterval(interval);
        setTimeout(() => setView('HOME'), 1000);
      }
    }, 1500);
  };

  const toggleDay = (day: string) => {
    setFormData(prev => {
      const exists = prev.days.includes(day);
      return {
        ...prev,
        days: exists ? prev.days.filter(d => d !== day) : [...prev.days, day]
      };
    });
  };

  // --- CALIBRATION SCREEN ---
  if (isCalibrating) {
    return (
      <div className="h-full flex flex-col items-center justify-center text-center px-6 animate-fade-in">
        <div className="relative mb-8">
          <div className="absolute inset-0 bg-[#D4A54A] blur-[60px] opacity-20 animate-pulse"></div>
          <Logo size={100} className="relative z-10 animate-bounce" />
        </div>
        <h2 className="text-2xl font-bold text-white mb-2">Construindo seu QG</h2>
        <p className="text-[#D4A54A] font-mono text-sm h-6">{calibrationText}</p>
        
        <div className="w-full max-w-xs mt-8 h-1 bg-[#1F1F1F] rounded-full overflow-hidden">
          <div className="h-full bg-[#D4A54A] animate-[width_6s_ease-in-out_forwards]" style={{width: '100%'}}></div>
        </div>
      </div>
    );
  }

  // --- WIZARD SCREENS ---
  return (
    <div className="h-full flex flex-col pt-6 pb-6 px-2">
      
      {/* Header / Progress */}
      <div className="flex items-center justify-between mb-8">
        <button 
          onClick={() => step > 1 && setStep(step - 1)}
          className={`text-sm text-[#777] ${step === 1 ? 'opacity-0' : 'opacity-100'}`}
        >
          Voltar
        </button>
        <div className="flex gap-2">
          {[1, 2, 3, 4].map(i => (
            <div 
              key={i} 
              className={`h-1.5 rounded-full transition-all duration-300 ${i <= step ? 'w-8 bg-[#D4A54A]' : 'w-2 bg-[#333]'}`} 
            />
          ))}
        </div>
        <span className="text-sm font-bold text-[#D4A54A]">{step}/{totalSteps}</span>
      </div>

      <div className="flex-1 overflow-y-auto no-scrollbar pb-4">
        
        {/* STEP 1: IDENTITY */}
        {step === 1 && (
          <div className="space-y-6 animate-fade-in">
            <div className="space-y-2">
              <h1 className="text-3xl font-bold text-white">Olá, Doutor(a).</h1>
              <p className="text-[#A3A3A3]">Para calibrar o algoritmo da Grey, preciso te conhecer melhor.</p>
            </div>

            <div className="space-y-4 pt-4">
              <Input 
                label="Como gostaria de ser chamado(a)?"
                placeholder="Ex: Dr. Silva" 
                value={formData.name}
                onChange={(e) => setFormData({...formData, name: e.target.value})}
                autoFocus
              />

              <div className="space-y-2">
                <label className="text-sm text-[#777] ml-1">Em qual fase você está?</label>
                <div className="grid grid-cols-1 gap-3">
                  {['Internato (5º/6º ano)', 'Recém-formado (Generalista)', 'Formado há +2 anos', 'Estudante (Ciclo Clínico)'].map(opt => (
                    <button
                      key={opt}
                      onClick={() => setFormData({...formData, stage: opt})}
                      className={`p-4 rounded-xl border text-left transition-all flex items-center justify-between ${
                        formData.stage === opt 
                        ? 'bg-[#D4A54A]/10 border-[#D4A54A] text-white' 
                        : 'bg-[#0A0A0A] border-[#1F1F1F] text-[#777] hover:border-[#333]'
                      }`}
                    >
                      <span className="font-medium">{opt}</span>
                      {formData.stage === opt && <Check size={18} className="text-[#D4A54A]" />}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* STEP 2: TARGET */}
        {step === 2 && (
          <div className="space-y-6 animate-fade-in">
             <div className="space-y-2">
              <h1 className="text-3xl font-bold text-white">Qual o objetivo?</h1>
              <p className="text-[#A3A3A3]">Definiremos o peso das matérias baseado na sua prova prioritária.</p>
            </div>

            <div className="grid grid-cols-2 gap-3">
              {['ENAMED', 'Revalida INEP', 'USP / SP', 'Unifesp', 'SUS / SP', 'Outros'].map(exam => (
                <button
                  key={exam}
                  onClick={() => setFormData({...formData, exam})}
                  className={`p-4 rounded-xl border flex flex-col items-center justify-center gap-2 aspect-square transition-all ${
                    formData.exam === exam 
                    ? 'bg-[#D4A54A] border-[#D4A54A] text-black shadow-lg shadow-[#D4A54A]/20' 
                    : 'bg-[#0A0A0A] border-[#1F1F1F] text-[#777] hover:border-[#D4A54A]'
                  }`}
                >
                  <GraduationCap size={28} />
                  <span className="font-bold text-sm text-center">{exam}</span>
                </button>
              ))}
            </div>

            <div className="space-y-2 pt-2">
              <label className="text-sm text-[#777] ml-1">Especialidade dos sonhos (Opcional)</label>
              <div className="relative">
                <Stethoscope size={18} className="absolute left-4 top-3.5 text-[#555]" />
                <input 
                  className="w-full bg-[#0A0A0A] border border-[#1F1F1F] rounded-xl pl-12 pr-4 py-3 text-white focus:border-[#D4A54A] focus:outline-none transition-colors"
                  placeholder="Ex: Cardiologia, Neuro..."
                  value={formData.specialty}
                  onChange={(e) => setFormData({...formData, specialty: e.target.value})}
                />
              </div>
            </div>
          </div>
        )}

        {/* STEP 3: ROUTINE */}
        {step === 3 && (
          <div className="space-y-6 animate-fade-in">
            <div className="space-y-2">
              <h1 className="text-3xl font-bold text-white">Sua Rotina</h1>
              <p className="text-[#A3A3A3]">Seja realista. A consistência vence a intensidade.</p>
            </div>

            <Card className="space-y-6 border-[#1F1F1F] bg-[#0A0A0A]">
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                   <label className="text-sm font-bold text-[#A3A3A3] flex items-center gap-2">
                     <Calendar size={16} className="text-[#D4A54A]" />
                     Dias de Estudo
                   </label>
                   <span className="text-xs text-[#555]">{formData.days.length} dias sel.</span>
                </div>
                <div className="flex justify-between">
                  {['D', 'S', 'T', 'Q', 'Q', 'S', 'S'].map((d, i) => {
                    const id = i.toString(); // Simple ID for demo
                    const isSelected = formData.days.includes(id);
                    return (
                      <button
                        key={i}
                        onClick={() => toggleDay(id)}
                        className={`
                          w-10 h-12 rounded-lg text-sm font-bold transition-all
                          ${isSelected 
                            ? 'bg-[#D4A54A] text-black shadow-[0_0_10px_rgba(212,165,74,0.3)] translate-y-[-2px]' 
                            : 'bg-[#1F1F1F] text-[#555] hover:bg-[#333]'}
                        `}
                      >
                        {d}
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="w-full h-px bg-[#1F1F1F]"></div>

              <div className="space-y-4">
                 <div className="flex items-center justify-between">
                   <label className="text-sm font-bold text-[#A3A3A3] flex items-center gap-2">
                     <Clock size={16} className="text-[#D4A54A]" />
                     Horas por dia
                   </label>
                   <span className="text-xl font-bold text-[#D4A54A]">{formData.hoursPerDay}h</span>
                 </div>
                 <input 
                    type="range" 
                    min="1" 
                    max="12" 
                    step="0.5"
                    value={formData.hoursPerDay}
                    onChange={(e) => setFormData({...formData, hoursPerDay: parseFloat(e.target.value)})}
                    className="w-full accent-[#D4A54A] h-2 bg-[#1F1F1F] rounded-lg appearance-none cursor-pointer"
                  />
                  <div className="flex justify-between text-[10px] text-[#555] font-medium uppercase tracking-widest">
                    <span>Manutenção</span>
                    <span>Intensivo</span>
                  </div>
              </div>
            </Card>
          </div>
        )}

        {/* STEP 4: REVIEW */}
        {step === 4 && (
          <div className="space-y-6 animate-fade-in h-full flex flex-col">
             <div className="space-y-2">
              <h1 className="text-3xl font-bold text-white">Tudo pronto?</h1>
              <p className="text-[#A3A3A3]">Confira os parâmetros antes de gerarmos seu plano.</p>
            </div>

            <div className="space-y-3">
              <div className="bg-[#0A0A0A] border border-[#1F1F1F] p-4 rounded-xl flex items-center gap-4">
                 <div className="w-10 h-10 rounded-full bg-[#1F1F1F] flex items-center justify-center text-[#D4A54A]">
                    <User size={20} />
                 </div>
                 <div>
                    <p className="text-xs text-[#555] uppercase">Perfil</p>
                    <p className="text-white font-medium">{formData.name || 'Doutor(a)'} • {formData.stage}</p>
                 </div>
              </div>

              <div className="bg-[#0A0A0A] border border-[#1F1F1F] p-4 rounded-xl flex items-center gap-4">
                 <div className="w-10 h-10 rounded-full bg-[#1F1F1F] flex items-center justify-center text-[#D4A54A]">
                    <GraduationCap size={20} />
                 </div>
                 <div>
                    <p className="text-xs text-[#555] uppercase">Foco</p>
                    <p className="text-white font-medium">{formData.exam} • {formData.specialty}</p>
                 </div>
              </div>

              <div className="bg-[#0A0A0A] border border-[#1F1F1F] p-4 rounded-xl flex items-center gap-4">
                 <div className="w-10 h-10 rounded-full bg-[#1F1F1F] flex items-center justify-center text-[#D4A54A]">
                    <Activity size={20} />
                 </div>
                 <div>
                    <p className="text-xs text-[#555] uppercase">Intensidade</p>
                    <p className="text-white font-medium">{formData.days.length} dias/sem • {formData.hoursPerDay}h/dia</p>
                 </div>
              </div>
            </div>

            <div className="bg-[#D4A54A]/5 border border-[#D4A54A]/20 p-4 rounded-xl flex gap-3">
              <BrainCircuit className="text-[#D4A54A] shrink-0" size={20} />
              <p className="text-xs text-[#D4A54A] leading-relaxed">
                "Com base nesses dados, a IA Grey sugere iniciar com ênfase em Ciclo Clínico e revisões espaçadas a cada 3 dias."
              </p>
            </div>
          </div>
        )}

      </div>

      <div className="mt-4">
        <Button 
          fullWidth 
          onClick={handleNext}
          disabled={step === 1 && !formData.name}
          className="flex items-center justify-center gap-2 h-14 text-lg font-bold"
        >
          {step === totalSteps ? 'Gerar Meu Plano' : 'Continuar'}
          {step !== totalSteps && <ChevronRight size={20} />}
        </Button>
      </div>
    </div>
  );
};
