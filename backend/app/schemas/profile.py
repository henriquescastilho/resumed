from pydantic import BaseModel
from typing import List, Dict, Optional
from datetime import date
from uuid import UUID

class UserProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    avatar_url: Optional[str] = None
    target_exams: List[str]
    available_days: List[int] # 1=Mon, 7=Sun
    hours_per_day: int
    level_assessment: Optional[Dict[str, str]] = None # {"Clinica": "medio"}
    target_exam_date: Optional[date] = None

class UserProfileOut(BaseModel):
    id: UUID
    full_name: Optional[str]
    email: str
    avatar_url: Optional[str]
    profile_data: Dict
    is_onboarding_complete: bool

    class Config:
        from_attributes = True
