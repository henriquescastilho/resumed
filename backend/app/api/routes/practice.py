from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Literal
from pydantic import BaseModel, field_validator
from pydantic import conint
from uuid import UUID
from datetime import datetime

from app.db.base import get_db
from app.models.user import User
from app.models.content import Question, QuestionAttempt
from app.api.deps import get_current_user

router = APIRouter()

class PracticeSessionRequest(BaseModel):
    mode: Literal["random", "topic", "smart"] = "random"
    count: conint(ge=1, le=50) = 10
    topic_ids: List[str] = []

class PracticeAnswerRequest(BaseModel):
    question_id: str
    chosen_option: str
    time_seconds: conint(ge=0, le=3600) = 0

    @field_validator("chosen_option")
    @classmethod
    def validate_option(cls, v: str) -> str:
        if v not in ("A", "B", "C", "D", "E"):
            raise ValueError("chosen_option must be A-E")
        return v

class QuestionOut(BaseModel):
    id: UUID
    text: str
    options: List[dict] # [{"id": "A", "text": "..."}]
    source: str
    
    class Config:
        from_attributes = True

@router.post("/session", response_model=List[QuestionOut])
def create_session(
    request: PracticeSessionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # MVP: Just return random questions
    questions = db.query(Question).limit(request.count).all()
    if not questions:
        # Initial Seed if empty
        seed_questions(db)
        questions = db.query(Question).limit(request.count).all()
        
    return questions

@router.post("/answer")
def submit_answer(
    request: PracticeAnswerRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    question = db.query(Question).filter(Question.id == request.question_id).first()
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")
        
    is_correct = (request.chosen_option == question.correct_option)
    
    attempt = QuestionAttempt(
        user_id=current_user.id,
        question_id=question.id,
        is_correct=is_correct,
        chosen_option=request.chosen_option,
        time_seconds=request.time_seconds
    )
    db.add(attempt)
    db.commit()
    
    return {
        "is_correct": is_correct,
        "correct_option": question.correct_option,
        "explanation": question.explanation
    }

def seed_questions(db: Session):
    q1 = Question(
        text="Qual o tratamento de escolha para Sífilis Primária?",
        options=[
            {"id": "A", "text": "Ciprofloxacino 500mg"},
            {"id": "B", "text": "Penicilina G Benzatina 2.4mi UI"},
            {"id": "C", "text": "Azitromicina 1g"},
            {"id": "D", "text": "Doxiciclina 100mg"}
        ],
        correct_option="B",
        explanation="O tratamento padrão ouro para sífilis primária é Penicilina Benzatina dose única.",
        source="Protocolo MS 2024"
    )
    db.add(q1)
    db.commit()
