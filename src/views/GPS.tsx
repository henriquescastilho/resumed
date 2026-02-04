
import React, { useState } from 'react';
import { MOCK_GPS } from '../constants';
import { Card } from '../components/Common';
import { Search, Flame, ChevronRight, CheckCircle2 } from 'lucide-react';

export const GPS: React.FC = () => {
  const [filter, setFilter] = useState('');

  return (
    <div className="space-y-6 pt-4 animate-fade-in">
      <div className="space-y-1">
        <h2 className="text-2xl font-black text-white">GPS</h2>
        <p className="text-[#777] text-sm">Navegue pelos conteúdos que mais caem.</p>
      </div>

      <div className="relative">
        <Search className="absolute left-4 top-3.5 text-[#555]" size={18} />
        <input 
          placeholder="Buscar tema ou subtema..." 
          className="w-full bg-[#0A0A0A] border border-[#1F1F1F] rounded-2xl pl-12 pr-4 py-3.5 text-white focus:border-[#D4A54A] focus:outline-none transition-all"
          value={filter}
          onChange={e => setFilter(e.target.value)}
        />
      </div>

      <div className="space-y-4">
        {MOCK_GPS.filter(item => 
          item.theme.toLowerCase().includes(filter.toLowerCase()) || 
          item.subtheme.toLowerCase().includes(filter.toLowerCase())
        ).map(item => (
          <Card key={item.id} className="p-5 border-[#1F1F1F] hover:border-[#D4A54A]/30 group cursor-pointer">
            <div className="flex justify-between items-start mb-4">
              <div className="space-y-1">
                <span className="text-[10px] font-bold text-[#555] uppercase tracking-widest">
                  {item.discipline} › {item.theme}
                </span>
                <h3 className="text-lg font-bold text-white group-hover:text-[#D4A54A] transition-colors">{item.subtheme}</h3>
              </div>
              {item.isMastered && <CheckCircle2 className="text-[#D4A54A]" size={20} />}
            </div>
            
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                 <div className="flex items-center gap-1.5">
                    <Flame size={14} className="text-[#D4A54A]" fill="currentColor" />
                    <span className="text-xs font-bold text-[#D4A54A]">{item.frequency}/ano</span>
                 </div>
                 <span className="text-[10px] font-bold text-[#555] uppercase">Frequência Alta</span>
              </div>
              <button className="flex items-center gap-1 text-xs font-bold text-[#D4A54A] uppercase tracking-widest">
                Testar <ChevronRight size={14} />
              </button>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
};
