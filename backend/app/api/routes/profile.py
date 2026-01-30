from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.base import get_db
from app.models.user import User
from app.schemas.profile import UserProfileOut, UserProfileUpdate
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/", response_model=UserProfileOut)
def get_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    profile_data = current_user.profile_data or {}
    
    # Check if onboarding is complete (MVP criteria)
    has_days = bool(profile_data.get("available_days"))
    has_hours = bool(profile_data.get("hours_per_day"))
    has_exams = bool(profile_data.get("target_exams"))
    
    is_complete = has_days and has_hours and has_exams
    
    return UserProfileOut(
        id=current_user.id,
        full_name=current_user.full_name,
        email=current_user.email,
        avatar_url=current_user.avatar_url,
        profile_data=profile_data,
        is_onboarding_complete=is_complete
    )

@router.put("/", response_model=UserProfileOut)
def update_profile(
    profile_in: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Validation
    if not (1 <= profile_in.hours_per_day <= 12):
        raise HTTPException(status_code=400, detail="Hours per day must be between 1 and 12")
    if not profile_in.available_days:
        raise HTTPException(status_code=400, detail="Select at least one day")
    if not profile_in.target_exams:
        raise HTTPException(status_code=400, detail="Select at least one exam")
        
    # Update Data
    current_data = current_user.profile_data or {}
    
    # Merge updates
    current_data["target_exams"] = profile_in.target_exams
    current_data["available_days"] = profile_in.available_days
    current_data["hours_per_day"] = profile_in.hours_per_day
    
    if profile_in.level_assessment:
        current_data["level_assessment"] = profile_in.level_assessment
    if profile_in.target_exam_date:
        current_data["target_exam_date"] = str(profile_in.target_exam_date)

    current_user.profile_data = current_data
    
    if profile_in.full_name:
        current_user.full_name = profile_in.full_name
    if profile_in.avatar_url:
        current_user.avatar_url = profile_in.avatar_url
        
    db.commit()
    db.refresh(current_user)
    
    # Recalculate 'is_onboarding_complete'
    is_complete = True
    
    return UserProfileOut(
        id=current_user.id,
        full_name=current_user.full_name,
        email=current_user.email,
        avatar_url=current_user.avatar_url,
        profile_data=current_user.profile_data,
        is_onboarding_complete=is_complete
    )
