from fastapi import APIRouter
from app.api.routes import auth, profile, plan, resucards, practice, grey

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(profile.router, prefix="/profile", tags=["profile"])
api_router.include_router(plan.router, prefix="/plan", tags=["plan"])
api_router.include_router(resucards.router, prefix="/resucards", tags=["resucards"])
api_router.include_router(practice.router, prefix="/practice", tags=["practice"])
api_router.include_router(grey.router, prefix="/grey", tags=["grey"])
