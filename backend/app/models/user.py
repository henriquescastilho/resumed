import uuid
from sqlalchemy import Column, String, Integer, DateTime, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.db.base import Base

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    firebase_uid = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    full_name = Column(String)
    avatar_url = Column(String)
    
    # Profile Data (JSONB)
    # target_exams: ["ENAMED", "USP"]
    # available_days: [1, 2, 3]
    # hours_per_day: 4
    # level_assessment: { "clinica": "medio", "cirurgia": "fraco" }
    profile_data = Column(JSON, default={})
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
