
import { Flashcard, UserStats } from '../types';
import { SRS_INTERVALS, XP_PER_LEVEL } from '../constants';

// --- Spaced Repetition Logic ---

/**
 * Calculates the next review date based on performance.
 * @param card The current flashcard
 * @param rating 'fail' (reset), 'hard' (keep/small bump), 'good' (next interval), 'easy' (jump interval)
 */
export const calculateNextReview = (card: Flashcard, rating: 'fail' | 'hard' | 'good' | 'easy'): Flashcard => {
  let newStep = card.srsStep;
  
  if (rating === 'fail') {
    newStep = 0;
  } else if (rating === 'hard') {
    // Keep same step or minimum 0, allows to review tomorrow
    newStep = Math.max(0, newStep); 
  } else if (rating === 'good') {
    newStep = newStep + 1;
  } else if (rating === 'easy') {
    newStep = newStep + 2;
  }

  // Cap the step at the max intervals defined
  if (newStep >= SRS_INTERVALS.length) {
    newStep = SRS_INTERVALS.length - 1;
  }

  const daysToAdd = SRS_INTERVALS[newStep];
  const nextDate = new Date();
  nextDate.setDate(nextDate.getDate() + daysToAdd);
  
  // Set time to start of day to avoid timezone confusion for simple logic
  nextDate.setHours(0,0,0,0);

  return {
    ...card,
    srsStep: newStep,
    lastReviewed: new Date().toISOString(),
    nextReview: nextDate.toISOString(),
    masteryLevel: rating === 'fail' ? 'low' : rating === 'easy' ? 'high' : 'medium'
  };
};

// --- Gamification Logic ---

export const addXP = (stats: UserStats, amount: number): { newStats: UserStats, leveledUp: boolean } => {
  let { xp, level } = stats;
  xp += amount;

  const xpForNextLevel = level * XP_PER_LEVEL;
  let leveledUp = false;

  if (xp >= xpForNextLevel) {
    level++;
    xp = xp - xpForNextLevel; // Carry over excess XP
    leveledUp = true;
  }

  return {
    newStats: { ...stats, xp, level },
    leveledUp
  };
};

export const checkBadges = (stats: UserStats, totalCardsReviewed: number): string[] => {
  const newBadges: string[] = [];
  // Example logic for badge unlocking
  if (!stats.badges.includes('b4') && totalCardsReviewed >= 1000) {
    newBadges.push('b4');
  }
  return newBadges;
};
