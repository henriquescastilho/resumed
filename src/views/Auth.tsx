
import React, { useState } from 'react';
import { ViewState, Theme } from '../types';
import { Button, Input } from '../components/Common';
import { Logo } from '../components/Logo';
import { Sun, Moon, Mail } from 'lucide-react';

interface AuthProps {
  setView: (v: ViewState) => void;
  theme: Theme;
  toggleTheme: () => void;
}

export const Auth: React.FC<AuthProps> = ({ setView, theme, toggleTheme }) => {
  const [isLogin, setIsLogin] = useState(true);

  return (
    <div className="h-full flex flex-col justify-center px-4 space-y-8 relative">
      
      {/* Theme Toggle */}
      <button 
         onClick={toggleTheme}
         className="absolute top-8 right-4 p-2 rounded-full border border-[#D4A54A] text-[#D4A54A]"
      >
         {theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />}
      </button>

      <div className="text-center space-y-4 flex flex-col items-center">
        <Logo size={80} className="drop-shadow-[0_0_10px_rgba(212,165,74,0.3)]" />
        <div>
           <h1 className="text-4xl font-bold tracking-tighter text-[#D4A54A]">RESUMED</h1>
           <p className="text-gray-500 dark:text-[#A3A3A3] mt-2">Acesse sua central de aprovação.</p>
        </div>
      </div>

      <div className="space-y-4 pt-4">
        {/* Social Login */}
        <Button variant="outline" fullWidth className="flex items-center justify-center gap-2">
           <svg className="w-5 h-5" viewBox="0 0 24 24">
             <path fill="currentColor" d="M12.545,10.239v3.821h5.445c-0.712,2.315-2.647,3.972-5.445,3.972c-3.332,0-6.033-2.701-6.033-6.032s2.701-6.032,6.033-6.032c1.498,0,2.866,0.549,3.921,1.453l2.814-2.814C17.503,2.988,15.139,2,12.545,2C7.021,2,2.543,6.477,2.543,12s4.478,10,10.002,10c8.396,0,10.249-7.85,9.426-11.748L12.545,10.239z"/>
           </svg>
           Entrar com Google
        </Button>
        
        <div className="relative py-2">
            <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-gray-200 dark:border-[#1F1F1F]"></div>
            </div>
            <div className="relative flex justify-center text-sm">
            <span className="px-2 bg-[#F9F9F9] dark:bg-black text-gray-400 dark:text-[#555]">Ou use e-mail</span>
            </div>
        </div>

        <div className="space-y-3">
            {!isLogin && <Input placeholder="Nome Completo" />}
            <Input placeholder="E-mail" type="email" />
            <Input placeholder="Senha" type="password" />
        </div>

        <Button fullWidth onClick={() => setView(isLogin ? 'HOME' : 'SETUP')}>
          {isLogin ? 'Entrar com Email' : 'Criar Conta'}
        </Button>
        
        <Button variant="ghost" fullWidth onClick={() => setIsLogin(!isLogin)}>
          {isLogin ? 'Não tem conta? Cadastre-se' : 'Já tenho uma conta'}
        </Button>
      </div>
    </div>
  );
};
