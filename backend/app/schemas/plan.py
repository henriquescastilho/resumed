from pydantic import BaseModel
from typing import List, Optional
from datetime import date
from uuid import UUID
from app.models.study_plan import TaskStatus, TaskType

class PlanTaskStatusUpdate(BaseModel):
    status: TaskStatus
    time_spent_min: Optional[int] = 0

class PlanTaskOut(BaseModel):
    id: UUID
    date: date
    title: str
    status: TaskStatus
    type: TaskType
    time_estimated_min: int
    time_spent_min: int
    topic_id: Optional[UUID]

    class Config:
        from_attributes = True

class RebalanceRequest(BaseModel):
    start_date: date
    end_date: date
