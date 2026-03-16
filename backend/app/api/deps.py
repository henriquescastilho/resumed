from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.db.base import get_db
from app.models.user import User
from app.services.auth_service import AuthService

security = HTTPBearer()

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """
    Validates the Bearer token and returns the current user.
    If the user doesn't exist in our DB but the token is valid, 
    we treat it as 401 (User must register/login via /auth/login first).
    """
    token = credentials.credentials
    try:
        payload = AuthService.verify_id_token(token)
        firebase_uid = payload.get("sub")
        
        if not firebase_uid:
             raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload"
            )
            
        user = db.query(User).filter(User.firebase_uid == firebase_uid).first()
        if not user:
             raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found"
            )
            
        return user
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Auth error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )
