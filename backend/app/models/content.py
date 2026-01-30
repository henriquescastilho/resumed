import uuid
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Boolean, Float, Text, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base

class Topic(Base):
    __tablename__ = "topics"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    discipline = Column(String, index=True) # Clinica Medica
    theme = Column(String, index=True) # Cardiologia
    subtheme = Column(String) # Insuficiencia Cardiaca
    
class Question(Base):
    __tablename__ = "questions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    text = Column(Text, nullable=False)
    options = Column(JSON, nullable=False) # [{"id": "A", "text": "Opcao A"}, ...]
    correct_option = Column(String, nullable=False)
    explanation = Column(Text)
    source = Column(String) # ENAMED 2024
    
    topic_id = Column(UUID(as_uuid=True), ForeignKey("topics.id"))
    topic = relationship("Topic")

class QuestionAttempt(Base):
    __tablename__ = "question_attempts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    question_id = Column(UUID(as_uuid=True), ForeignKey("questions.id"))
    
    is_correct = Column(Boolean, nullable=False)
    chosen_option = Column(String)
    time_seconds = Column(Integer)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
class Flashcard(Base):
    __tablename__ = "flashcards"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    
    front = Column(Text, nullable=False)
    back = Column(Text, nullable=False)
    
    # SRS Fields
    srs_step = Column(Integer, default=0)
    next_review = Column(DateTime(timezone=True), index=True)
    last_review = Column(DateTime(timezone=True))
    ease_factor = Column(Float, default=2.5)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
