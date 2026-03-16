from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timezone
from pydantic import BaseModel
from uuid import UUID

from app.db.base import get_db
from app.models.user import User
from app.models.content import Flashcard
from app.api.deps import get_current_user
from app.services.srs_service import SRSService

router = APIRouter()

class ReviewRequest(BaseModel):
    rating: int # 0, 1, 2, 3

class FlashcardOut(BaseModel):
    id: UUID
    front: str
    back: str
    next_review: datetime
    
    class Config:
        from_attributes = True

@router.get("/due", response_model=List[FlashcardOut])
def get_due_cards(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    now = datetime.now(timezone.utc)
    cards = db.query(Flashcard).filter(
        Flashcard.user_id == current_user.id,
        Flashcard.next_review <= now
    ).limit(50).all() # Cap for session
    return cards

@router.post("/{card_id}/review")
def review_card(
    card_id: str,
    review: ReviewRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    card = db.query(Flashcard).filter(
        Flashcard.id == card_id,
        Flashcard.user_id == current_user.id
    ).first()
    
    if not card:
        raise HTTPException(status_code=404, detail="Card not found")
        
    try:
        updated_card = SRSService.calculate_next_review(card, review.rating)
        db.commit()
        return {"status": "reviewed", "next_review": updated_card.next_review}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/seed")
def seed_cards(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Temporary endpoint to seed cards for MVP
    mock_cards = [
        Flashcard(user_id=current_user.id, front="Tríade de Beck?", back="Hipotensão, Estase Jugular, Bulhas Abafadas", next_review=datetime.now(timezone.utc)),
        Flashcard(user_id=current_user.id, front="Agente etiológico da Erisipela?", back="Streptococcus pyogenes (Grupo A)", next_review=datetime.now(timezone.utc)),
        Flashcard(user_id=current_user.id, front="Critérios de Light?", back="Diferenciar exsudato de transudato pleural", next_review=datetime.now(timezone.utc)),
    ]
    db.add_all(mock_cards)
    db.commit()
    return {"message": "Cards seeded"}
