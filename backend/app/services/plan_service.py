from sqlalchemy.orm import Session
from datetime import date, timedelta
from typing import List
from app.models.user import User
from app.models.study_plan import StudyPlanTask, TaskType, TaskStatus
from app.models.content import Topic

class PlanService:
    @staticmethod
    def generate_week_plan(db: Session, user: User, start_date: date, end_date: date) -> List[StudyPlanTask]:
        """
        Generates a simple study plan for the given range based on user's available days and hours.
        MVP Logic:
        - Iterates through days in range.
        - If day is in available_days:
          - Creates tasks.
        """
        
        # Parse profile data
        profile = user.profile_data or {}
        available_days = profile.get("available_days", []) # Expecting [1, 2, 3...]
        hours_per_day = profile.get("hours_per_day", 0)
        
        if not available_days or hours_per_day <= 0:
            return [] # Cannot generate without profile

        generated_tasks = []
        current_date = start_date
        
        # Get all topics for simple distribution (MVP: Random/Round-robin)
        topics = db.query(Topic).limit(20).all()
        topic_idx = 0
        
        while current_date <= end_date:
            # Python weekday: 0=Mon, 6=Sun. 
            # App convention: 1=Mon, 7=Sun.
            weekday = current_date.weekday() + 1 
            
            if weekday in available_days:
                # Simple logic: 1 task per hour logic
                tasks_count = max(1, hours_per_day) # MVP simplification: 1 hour blocks
                
                for i in range(tasks_count):
                    topic = topics[topic_idx % len(topics)] if topics else None
                    if topics: topic_idx += 1
                    
                    task_title = f"Estudar {topic.theme if topic else 'Geral'}"
                    if i == tasks_count - 1 and tasks_count > 1:
                         task_title = "Revisão e Questões"
                    
                    task = StudyPlanTask(
                        user_id=user.id,
                        date=current_date,
                        title=task_title,
                        status=TaskStatus.PENDING,
                        type=TaskType.THEORY,
                        time_estimated_min=60, # 1 hour default
                        topic_id=topic.id if topic else None
                    )
                    db.add(task)
                    generated_tasks.append(task)
            
            current_date += timedelta(days=1)
            
        db.commit()
        return generated_tasks

    @staticmethod
    def rebalance_plan(db: Session, user: User) -> dict:
        """
        Rebalances the plan:
        1. Finds all PENDING tasks before current date.
        2. Updates their status to SKIPPED.
        3. Creates a consolidated 'Review' task for today.
        Returns counts for the API response.
        """
        today = date.today()

        # 1. Find overdue pending tasks
        overdue_tasks = db.query(StudyPlanTask).filter(
            StudyPlanTask.user_id == user.id,
            StudyPlanTask.date < today,
            StudyPlanTask.status == TaskStatus.PENDING
        ).all()

        if not overdue_tasks:
            return {"skipped": 0, "created": 0}

        # 2. Mark them as SKIPPED
        skipped_topics = set()
        for task in overdue_tasks:
            task.status = TaskStatus.SKIPPED
            if task.topic_id:
                skipped_topics.add(task.topic_id)

        created = 0
        # 3. Create review task for today
        if skipped_topics:
            review_task = StudyPlanTask(
                user_id=user.id,
                date=today,
                title="Revisão de Atrasados",
                status=TaskStatus.PENDING,
                type=TaskType.REVIEW,
                time_estimated_min=60,
                topic_id=None
            )
            db.add(review_task)
            created = 1

        db.commit()
        return {"skipped": len(overdue_tasks), "created": created}
