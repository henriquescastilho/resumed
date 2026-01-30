from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date
from app.db.base import get_db
from app.models.user import User
from app.models.study_plan import StudyPlanTask
from app.schemas.plan import PlanTaskOut, PlanTaskStatusUpdate, RebalanceRequest
from app.api.deps import get_current_user
from app.services.plan_service import PlanService

router = APIRouter()

@router.get("/", response_model=List[PlanTaskOut])
def get_plan(
    start_date: date,
    end_date: date,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    tasks = db.query(StudyPlanTask).filter(
        StudyPlanTask.user_id == current_user.id,
        StudyPlanTask.date >= start_date,
        StudyPlanTask.date <= end_date
    ).all()
    
    if not tasks:
        # Generate default plan if empty
        tasks = PlanService.generate_week_plan(db, current_user, start_date, end_date)
        
    return tasks

@router.put("/{task_id}/status", response_model=PlanTaskOut)
def update_task_status(
    task_id: str,
    status_in: PlanTaskStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = db.query(StudyPlanTask).filter(
        StudyPlanTask.id == task_id,
        StudyPlanTask.user_id == current_user.id
    ).first()
    
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    task.status = status_in.status
    if status_in.time_spent_min is not None:
        task.time_spent_min = status_in.time_spent_min
        
    db.commit()
    db.refresh(task)
    return task

@router.post("/rebalance")
def rebalance_plan(
    request: RebalanceRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Call service (mocked/simple for now)
    return {"message": "Plan rebalanced"}
