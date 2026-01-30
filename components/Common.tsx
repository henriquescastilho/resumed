
import React from 'react';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

// Utility for merging tailwind classes
function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Button Component
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'solid' | 'outline' | 'ghost';
  fullWidth?: boolean;
}

export const Button: React.FC<ButtonProps> = ({ 
  children, 
  variant = 'solid', 
  fullWidth = false, 
  className, 
  ...props 
}) => {
  const baseStyles = "px-6 py-3 rounded-xl font-medium transition-all duration-300 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed";
  
  const variants = {
    solid: "bg-[#D4A54A] text-white dark:text-black hover:bg-[#c49642] shadow-[0_0_15px_rgba(212,165,74,0.3)]",
    outline: "border border-[#D4A54A] text-[#D4A54A] hover:bg-[#D4A54A] hover:text-white dark:hover:text-black",
    ghost: "text-[#777] dark:text-[#A3A3A3] hover:text-black dark:hover:text-white"
  };

  return (
    <button 
      className={cn(baseStyles, variants[variant], fullWidth ? "w-full" : "", className)}
      {...props}
    >
      {children}
    </button>
  );
};

// Card Component
export const Card: React.FC<React.HTMLAttributes<HTMLDivElement>> = ({ children, className, ...props }) => {
  return (
    <div 
      className={cn(
        "bg-white dark:bg-[#0A0A0A] border border-gray-200 dark:border-[#1F1F1F] rounded-2xl p-5 shadow-sm dark:shadow-none hover:border-[#D4A54A]/30 transition-colors duration-300", 
        className
      )} 
      {...props}
    >
      {children}
    </div>
  );
};

// Input Component
interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
}

export const Input: React.FC<InputProps> = ({ label, className, ...props }) => {
  return (
    <div className="w-full space-y-2">
      {label && <label className="text-sm text-[#555] dark:text-[#A3A3A3] ml-1">{label}</label>}
      <input 
        className={cn(
          "w-full bg-white dark:bg-[#0A0A0A] border border-gray-200 dark:border-[#333] rounded-xl px-4 py-3 text-black dark:text-white placeholder-gray-400 dark:placeholder-[#555] focus:outline-none focus:border-[#D4A54A] focus:ring-1 focus:ring-[#D4A54A] transition-all",
          className
        )}
        {...props}
      />
    </div>
  );
};

// Progress Bar
export const ProgressBar: React.FC<{ progress: number, className?: string }> = ({ progress, className }) => {
  return (
    <div className={cn("w-full h-2 bg-gray-200 dark:bg-[#1F1F1F] rounded-full overflow-hidden", className)}>
      <div 
        className="h-full bg-[#D4A54A] transition-all duration-500 ease-out shadow-[0_0_10px_rgba(212,165,74,0.5)]"
        style={{ width: `${progress}%` }}
      />
    </div>
  );
};
