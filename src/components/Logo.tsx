import React from 'react';
import logoUrl from '@/assets/resumed-logo.png';

export const Logo: React.FC<{ size?: number, className?: string }> = ({ size = 48, className = "" }) => {
  return (
    <img 
      src={logoUrl} 
      alt="Resumed Logo"
      width={size}
      height={size}
      className={className}
      style={{ objectFit: 'contain' }}
    />
  );
};
