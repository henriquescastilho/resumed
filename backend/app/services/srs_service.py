from datetime import datetime, timedelta
from app.models.content import Flashcard

class SRSService:
    """
    Spaced Repetition System (SuperMemo-2 Adapted)
    
    Ratings:
    0 - Fail (Again)
    1 - Hard (Review in < 3 days)
    2 - Good (Standard SMv2)
    3 - Easy (Bonus interval)
    """
    
    @staticmethod
    def calculate_next_review(card: Flashcard, rating: int) -> Flashcard:
        if rating not in [0, 1, 2, 3]:
            raise ValueError("Invalid rating")
            
        now = datetime.now()
        
        # Current values
        step = card.srs_step
        ease = card.ease_factor
        
        new_interval = 0
        new_ease = ease
        
        if rating == 0: # Fail
            step = 0
            new_interval = 1 # Review tomorrow
            # Ease drops penalty
            new_ease = max(1.3, ease - 0.2)
            
        elif rating == 1: # Hard
            # Doesn't reset, but interval growth is small
            step = 0 # Or keep current step but minimal interval? SM2 resets on hard usually or treats as fail. 
            # In Anki: Hard passes but with 1.2x. Here let's treat as weak pass.
            new_interval = 3 
            new_ease = max(1.3, ease - 0.15)
            
        elif rating == 2: # Good
            if step == 0:
                new_interval = 1
            elif step == 1:
                new_interval = 6
            else:
                new_interval = round(step * ease)
            
            step += 1
            
        elif rating == 3: # Easy
            if step == 0:
                new_interval = 4
            elif step == 1:
                new_interval = 10 # Bonus
            else:
                new_interval = round(step * ease * 1.3) # Bonus multiplier
            
            step += 1
            new_ease = ease + 0.15
            
        # Update Card
        card.srs_step = step
        card.ease_factor = new_ease
        card.last_review = now
        card.next_review = now + timedelta(days=new_interval)
        
        return card
