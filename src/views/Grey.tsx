import React, { useState, useEffect, useRef } from 'react';
import { initChat, sendMessageToGrey } from '../services/geminiService';
import { ChatMessage } from '../types';
import { Input, Button } from '../components/Common';
import { Send, Bot, User } from 'lucide-react';

export const Grey: React.FC = () => {
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: '0',
      role: 'model',
      text: 'Olá. Eu sou a Grey. Estou aqui para tirar suas dúvidas estritamente médicas e auxiliar na sua preparação para o ENAMED. Como posso ajudar hoje?',
      timestamp: new Date()
    }
  ]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    initChat();
  }, []);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSend = async () => {
    if (!input.trim() || loading) return;

    const userMsg: ChatMessage = {
      id: Date.now().toString(),
      role: 'user',
      text: input,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMsg]);
    setInput('');
    setLoading(true);

    const responseText = await sendMessageToGrey(userMsg.text);

    const botMsg: ChatMessage = {
      id: (Date.now() + 1).toString(),
      role: 'model',
      text: responseText,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, botMsg]);
    setLoading(false);
  };

  return (
    <div className="h-full flex flex-col">
      <div className="flex items-center gap-3 pb-4 border-b border-[#1F1F1F] mb-4">
        <div className="w-10 h-10 rounded-full bg-[#D4A54A] flex items-center justify-center border-2 border-black shadow-lg">
          <Bot size={20} className="text-black" />
        </div>
        <div>
          <h2 className="text-white font-bold">Grey</h2>
          <div className="flex items-center gap-1.5">
             <div className="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse"></div>
             <p className="text-[10px] text-[#777] uppercase tracking-wider">IA Médica Online</p>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto space-y-4 pr-2">
        {messages.map((msg) => (
          <div 
            key={msg.id} 
            className={`flex gap-3 ${msg.role === 'user' ? 'flex-row-reverse' : 'flex-row'}`}
          >
            <div className={`
              w-8 h-8 rounded-full flex-shrink-0 flex items-center justify-center
              ${msg.role === 'user' ? 'bg-[#1F1F1F]' : 'bg-[#D4A54A]'}
            `}>
              {msg.role === 'user' ? <User size={14} className="text-[#777]" /> : <Bot size={14} className="text-black" />}
            </div>

            <div className={`
              max-w-[80%] p-3 rounded-2xl text-sm leading-relaxed
              ${msg.role === 'user' 
                ? 'bg-[#1F1F1F] text-white border border-[#333] rounded-tr-none' 
                : 'bg-[#D4A54A] text-black font-medium shadow-[0_0_10px_rgba(212,165,74,0.1)] rounded-tl-none'}
            `}>
              {msg.text.split('\n').map((line, i) => (
                 <p key={i} className={i > 0 ? 'mt-2' : ''}>{line}</p>
              ))}
            </div>
          </div>
        ))}
        {loading && (
          <div className="flex gap-3">
             <div className="w-8 h-8 rounded-full bg-[#D4A54A] flex items-center justify-center">
                <Bot size={14} className="text-black" />
             </div>
             <div className="bg-[#111] px-4 py-3 rounded-2xl rounded-tl-none border border-[#222]">
                <div className="flex gap-1">
                  <div className="w-1.5 h-1.5 bg-[#555] rounded-full animate-bounce"></div>
                  <div className="w-1.5 h-1.5 bg-[#555] rounded-full animate-bounce delay-100"></div>
                  <div className="w-1.5 h-1.5 bg-[#555] rounded-full animate-bounce delay-200"></div>
                </div>
             </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      <div className="pt-4 mt-2">
        <div className="relative">
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleSend()}
            placeholder="Pergunte sobre medicina..."
            className="w-full bg-[#0A0A0A] border border-[#333] rounded-full pl-5 pr-12 py-3.5 text-white focus:border-[#D4A54A] focus:outline-none transition-colors placeholder-[#444]"
          />
          <button 
            onClick={handleSend}
            disabled={!input.trim()}
            className="absolute right-2 top-1.5 p-2 bg-[#D4A54A] rounded-full text-black hover:scale-105 active:scale-95 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Send size={18} />
          </button>
        </div>
      </div>
    </div>
  );
};
