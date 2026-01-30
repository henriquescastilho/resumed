import uuid
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Date, Enum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base
import enum

class TaskStatus(str, enum.Enum):
    PENDING = "pending"
    DONE = "done"
    SKIPPED = "skipped"
    REVIEW = "review"

class TaskType(str, enum.Enum):
    THEORY = "theory"
    EXERCISE = "exercise"
    REVIEW = "review"

class StudyPlanTask(Base):
    __tablename__ = "study_plan_tasks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    
    date = Column(Date, nullable=False, index=True)
    topic_id = Column(UUID(as_uuid=True), ForeignKey("topics.id"), nullable=True) # Can be null for generic tasks
    
    title = Column(String, nullable=False)
    status = Column(Enum(TaskStatus), default=TaskStatus.PENDING)
    type = Column(Enum(TaskType), default=TaskType.THEORY)
    
    time_estimated_min = Column(Integer, default=30)
    time_spent_min = Column(Integer, default=0)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    user = relationship("User")
    topic = relationship("Topic")
