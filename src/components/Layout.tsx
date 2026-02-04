
import React from 'react';
import { Home, Bot, BarChart2, Clock, Users, Sun, Moon, Target, LayoutDashboard, BrainCircuit } from 'lucide-react';
import { ViewState, Theme } from '../types';
import { Logo } from './Logo';

interface LayoutProps {
  children: React.ReactNode;
  currentView: ViewState;
  setView: (view: ViewState) => void;
  showNav?: boolean;
  theme: Theme;
  toggleTheme: () => void;
}

export const Layout: React.FC<LayoutProps> = ({ children, currentView, setView, showNav = true, theme, toggleTheme }) => {
  return (
    <div className="min-h-screen bg-[#F9F9F9] dark:bg-black text-[#111] dark:text-[#F2F2F2] font-sans selection:bg-[#D4A54A] selection:text-black flex flex-col md:flex-row transition-colors duration-300">
      
      {/* DESKTOP SIDEBAR */}
      {showNav && (
        <aside className="hidden md:flex w-64 flex-col border-r border-gray-200 dark:border-[#1F1F1F] bg-white dark:bg-[#050505] p-6 justify-between shrink-0 h-screen sticky top-0">
          <div>
            <div className="flex items-center gap-3 mb-10 pl-2">
              <Logo size={40} />
              <span className="text-xl font-bold tracking-tighter text-[#D4A54A]">RESUMED</span>
            </div>
            
            <nav className="space-y-2">
              <SidebarItem icon={<Home size={20} />} label="Visão Geral" active={currentView === 'HOME'} onClick={() => setView('HOME')} />
              <SidebarItem icon={<Target size={20} />} label="Meu Plano" active={currentView === 'PLAN'} onClick={() => setView('PLAN')} />
              <SidebarItem icon={<BrainCircuit size={20} />} label="Praticar" active={currentView === 'PRACTICE' || currentView === 'RESUCARDS'} onClick={() => setView('PRACTICE')} />
              <SidebarItem icon={<BarChart2 size={20} />} label="Análise" active={currentView === 'PERFORMANCE'} onClick={() => setView('PERFORMANCE')} />
              <SidebarItem icon={<Users size={20} />} label="Comunidade" active={currentView === 'CONNECT'} onClick={() => setView('CONNECT')} />
              <SidebarItem icon={<Clock size={20} />} label="Histórico" active={currentView === 'HISTORY'} onClick={() => setView('HISTORY')} />
            </nav>
          </div>

          <div className="space-y-4">
             {/* AI Button Desktop */}
             <button 
                onClick={() => setView('GREY')}
                className={`
                  w-full flex items-center gap-3 p-3 rounded-xl transition-all
                  ${currentView === 'GREY' ? 'bg-[#D4A54A] text-black shadow-lg' : 'bg-[#1F1F1F] text-white hover:bg-[#333]'}
                `}
             >
                <Bot size={20} />
                <span className="font-bold">Grey AI</span>
             </button>

             <button 
               onClick={toggleTheme}
               className="flex items-center gap-3 px-4 py-2 text-sm text-gray-500 dark:text-[#777] hover:text-[#D4A54A] transition-colors"
             >
               {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
               <span>{theme === 'dark' ? 'Modo Claro' : 'Modo Escuro'}</span>
             </button>
          </div>
        </aside>
      )}

      {/* MAIN CONTENT AREA */}
      <main className="flex-1 h-screen overflow-y-auto no-scrollbar relative w-full">
        <div className="max-w-4xl mx-auto w-full p-4 md:p-8 pb-24 md:pb-8">
          
          {/* Mobile Theme Toggle (only if nav hidden or specific views) */}
          <div className="md:hidden absolute top-4 right-4 z-40">
            {['HOME', 'PLAN', 'PERFORMANCE', 'HISTORY', 'CONNECT', 'PRACTICE'].includes(currentView) && (
              <button 
                onClick={toggleTheme}
                className="p-2 rounded-full bg-white dark:bg-[#1F1F1F] border border-gray-200 dark:border-[#333] text-[#D4A54A] shadow-sm"
              >
                {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
              </button>
            )}
          </div>

          {children}
        </div>
      </main>

      {/* MOBILE BOTTOM NAVIGATION */}
      {showNav && (
        <div className="md:hidden fixed bottom-0 left-0 right-0 bg-white/95 dark:bg-black/95 backdrop-blur-md border-t border-gray-200 dark:border-[#1F1F1F] py-2 pb-6 z-50 transition-colors duration-300">
          <div className="flex justify-around items-center px-2">
            <NavItem icon={<Home size={20} />} label="Home" active={currentView === 'HOME'} onClick={() => setView('HOME')} />
            <NavItem icon={<Target size={20} />} label="Plano" active={currentView === 'PLAN'} onClick={() => setView('PLAN')} />
            
            {/* FAB for AI */}
            <button 
              onClick={() => setView('GREY')}
              className={`
                -mt-8 w-14 h-14 rounded-full bg-[#D4A54A] flex items-center justify-center 
                shadow-[0_0_20px_rgba(212,165,74,0.4)] border-4 border-white dark:border-black transition-transform active:scale-95
                ${currentView === 'GREY' ? 'scale-110' : ''}
              `}
            >
              <Bot size={26} className="text-white dark:text-black" />
            </button>

            <NavItem icon={<Users size={20} />} label="Conectar" active={currentView === 'CONNECT'} onClick={() => setView('CONNECT')} />
            <NavItem icon={<BarChart2 size={20} />} label="Análise" active={currentView === 'PERFORMANCE'} onClick={() => setView('PERFORMANCE')} />
          </div>
        </div>
      )}
    </div>
  );
};

const NavItem = ({ icon, label, active, onClick }: { icon: React.ReactNode, label: string, active: boolean, onClick: () => void }) => (
  <button 
    onClick={onClick}
    className={`flex flex-col items-center gap-1 p-2 w-16 transition-colors ${active ? 'text-[#D4A54A]' : 'text-gray-400 dark:text-[#555] hover:text-[#D4A54A] dark:hover:text-[#A3A3A3]'}`}
  >
    {icon}
    <span className="text-[10px] font-medium tracking-wide">{label}</span>
  </button>
);

const SidebarItem = ({ icon, label, active, onClick }: { icon: React.ReactNode, label: string, active: boolean, onClick: () => void }) => (
  <button
    onClick={onClick}
    className={`
      w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200
      ${active 
        ? 'bg-[#D4A54A]/10 text-[#D4A54A] border-r-2 border-[#D4A54A]' 
        : 'text-gray-500 dark:text-[#777] hover:bg-gray-100 dark:hover:bg-[#111] hover:text-[#111] dark:hover:text-[#FFF]'}
    `}
  >
    {icon}
    <span className="text-sm font-medium">{label}</span>
  </button>
);
