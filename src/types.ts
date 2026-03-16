
export type ViewState = 
  | 'SPLASH' 
  | 'ONBOARDING_WELCOME'
  | 'ONBOARDING_EXAMS'
  | 'ONBOARDING_DAYS'
  | 'ONBOARDING_HOURS'
  | 'ONBOARDING_DISTRIBUTION'
  | 'ONBOARDING_ASSESSMENT'
  | 'ONBOARDING_PROCESSING'
  | 'HOME' 
  | 'GPS'
  | 'PRACTICE'
  | 'ESSAY'
  | 'RESUCARDS' 
  | 'SCHEDULE'
  | 'PERFORMANCE' 
  | 'HISTORY'
  | 'COMMUNITY'
  | 'GREY'
  | 'PLAN'
  | 'CONNECT';

export type Theme = 'light' | 'dark';

export interface UserProfile {
  name: string;
  targetExams: string[];
  availableDays: string[]; // ['0', '1'...]
  hoursPerDay: Record<string, number>; // dayIndex: hours
  subjectWeights: Record<string, 'pouco' | 'medio' | 'bastante'>;
  specialty?: string;
}

export interface GPSItem {
  id: string;
  discipline: string;
  theme: string;
  subtheme: string;
  frequency: number; // 0-10
  isMastered: boolean;
}

export interface Task {
  id: string;
  area: string;
  theme: string;
  subject: string;
  duration: number; // minutes
  completed: boolean;
  day: string;
  type: 'exercise' | 'reading' | 'class';
}

export interface ChatMessage {
  id: string;
  role: 'user' | 'model';
  text: string;
  timestamp: Date;
}

export interface Flashcard {
  id: string;
  front: string;
  back: string;
  masteryLevel: 'low' | 'medium' | 'high';
  lastReviewed?: string;
  nextReview?: string;
  srsStep: number;
}

export interface UserStats {
  xp: number;
  level: number;
  streak: number;
  badges: string[];
  cardsReviewedToday: number;
}

export interface EssayTopic {
  id: string;
  title: string;
  source: string;
  year: number;
}

// Added Badge interface to support gamification system
export interface Badge {
  id: string;
  name: string;
  icon: string;
  unlocked: boolean;
}
