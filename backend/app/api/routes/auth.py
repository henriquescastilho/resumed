from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from app.db.base import get_db
from app.models.user import User
from app.services.auth_service import AuthService

router = APIRouter()

class LoginRequest(BaseModel):
    id_token: str

class UserResponse(BaseModel):
    id: str
    full_name: Optional[str]
    email: str
    avatar_url: Optional[str]

class LoginResponse(BaseModel):
    user: UserResponse

@router.post("/login", response_model=LoginResponse)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    """
    Validates Google ID Token.
    Creates user if not exists (Idempotent).
    Returns user data.
    """
    try:
        payload = AuthService.verify_id_token(request.id_token)
    except HTTPException as e:
        raise e
    except Exception as e:
        print(f"Auth login error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed"
        )

    firebase_uid = payload.get("sub")
    email = payload.get("email")
    name = payload.get("name")
    picture = payload.get("picture")

    if not firebase_uid or not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token missing required claims (sub, email)"
        )

    # Check if user exists
    user = db.query(User).filter(User.firebase_uid == firebase_uid).first()

    if not user:
        # Create new user
        user = User(
            firebase_uid=firebase_uid,
            email=email,
            full_name=name,
            avatar_url=picture,
            profile_data={}
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    else:
        # Optional: Update basics on login
        if user.full_name != name or user.avatar_url != picture:
            user.full_name = name
            user.avatar_url = picture
            db.commit()
            db.refresh(user)

    return {
        "user": {
            "id": str(user.id),
            "full_name": user.full_name,
            "email": user.email,
            "avatar_url": user.avatar_url
        }
    }
