
import { GPSItem, EssayTopic, Flashcard, Task, Badge } from './types';

export const THEME = {
  gold: '#D4A54A',
  black: '#000000',
  blackSec: '#050505',
  border: '#1F1F1F',
  gray: '#777777',
  white: '#FFFFFF'
};

export const SUBJECTS = [
  'Clínica Médica',
  'Cirurgia Geral',
  'Pediatria',
  'Ginecologia e Obstetrícia',
  'Medicina Preventiva',
  'Ética Médica'
];

export const MOCK_GPS: GPSItem[] = [
  { id: '1', discipline: 'Clínica Médica', theme: 'Cardiologia', subtheme: 'Insuficiência Cardíaca', frequency: 9, isMastered: false },
  { id: '2', discipline: 'Clínica Médica', theme: 'Cardiologia', subtheme: 'Hipertensão Arterial', frequency: 10, isMastered: true },
  { id: '3', discipline: 'Cirurgia Geral', theme: 'Trauma', subtheme: 'ATLS 10ª Edição', frequency: 9, isMastered: false },
  { id: '4', discipline: 'Pediatria', theme: 'Neonatologia', subtheme: 'Icterícia Neonatal', frequency: 7, isMastered: false },
  { id: '5', discipline: 'Ginecologia', theme: 'Obstetrícia', subtheme: 'Pré-eclâmpsia', frequency: 8, isMastered: true },
];

export const MOCK_ESSAY_TOPICS: EssayTopic[] = [
  { id: '1', title: 'A interiorização da medicina no Brasil: desafios e perspectivas', source: 'Simulado ENAMED', year: 2024 },
  { id: '2', title: 'O papel da telemedicina no acesso à saúde pública', source: 'Revalida INEP', year: 2023 },
  { id: '3', title: 'Ética médica na era da inteligência artificial', source: 'USP-SP', year: 2024 },
];

export const SRS_INTERVALS = [1, 3, 7, 15, 30];

export const MOCK_FLASHCARDS: Flashcard[] = [
  { id: '1', front: 'Tríade de Beck?', back: 'Hipotensão, Hipofonese de bulhas e Turgência Jugular.', masteryLevel: 'medium', srsStep: 1 },
  { id: '2', front: 'Sinal de Murphy indica o quê?', back: 'Colecystite Aguda.', masteryLevel: 'high', srsStep: 3 },
  { id: '3', front: 'Tratamento de escolha para Sífilis?', back: 'Penicilina Benzatina.', masteryLevel: 'low', srsStep: 0 },
];

// Added missing global constants
export const XP_PER_LEVEL = 1000;

// Added missing mock data for gamification and history
export const BADGES: Badge[] = [
  { id: 'b1', name: 'Primeiros Passos', icon: 'Shield', unlocked: true },
  { id: 'b2', name: 'Maratonista', icon: 'Flag', unlocked: false },
  { id: 'b3', name: 'Sábio', icon: 'Book', unlocked: false },
  { id: 'b4', name: 'Mestre da Saúde', icon: 'HeartPulse', unlocked: false },
];

export const MOCK_TASKS: Task[] = [
  { id: 't1', area: 'Clínica Médica', theme: 'Cardiologia', subject: 'Insuficiência Cardíaca', duration: 60, completed: false, day: '1', type: 'exercise' },
];

export const MOCK_HISTORY = [
  { id: 'h1', type: 'exercise', date: '2024-05-20', title: 'Simulado Cardiologia', result: '85%' },
  { id: 'h2', type: 'essay', date: '2024-05-19', title: 'Ética Médica e IA', result: '9.5/10' },
  { id: 'h3', type: 'exam', date: '2024-05-18', title: 'Provão ENAMED 2023', result: '78%' },
];

export const MOCK_PEER_QUESTIONS = [
  { id: 'p1', author: 'Dr. Lucas', specialty: 'Pediatria', timeAgo: '2h', text: 'Dúvida sobre manejo de asma em crises agudas em lactentes...', responses: 5 },
  { id: 'p2', author: 'Dra. Ana', specialty: 'Ginecologia', timeAgo: '5h', text: 'Qual a conduta atualizada para rastreio de câncer de colo de útero?', responses: 12 },
];
