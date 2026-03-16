from fastapi import APIRouter, Depends, Request, HTTPException
from pydantic import BaseModel, constr
from typing import Optional, List, Dict
from app.api.deps import get_current_user
from app.models.user import User
from app.services.grey_service import GreyService
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

router = APIRouter()

class GreyMessageRequest(BaseModel):
    message: constr(max_length=2000)
    context: Dict[str, str] = {} # screen, topic

class FlashcardDTO(BaseModel):
    front: str
    back: str

class GreyResponse(BaseModel):
    answer_markdown: str
    flashcard: Optional[FlashcardDTO] = None
    tags: List[str] = []

VALID_SCREENS = {"home", "plan", "resucards", "performance", "practice", "exam", "grey", ""}
VALID_TOPICS = {
    "clinica_medica", "cirurgia", "pediatria", "ginecologia",
    "preventiva", "outras", ""
}

@router.post("/message", response_model=GreyResponse)
@limiter.limit("20/minute")
async def send_message(
    request_obj: GreyMessageRequest,
    request: Request,
    current_user: User = Depends(get_current_user)
):
    # Validate context values against allowlists
    screen = request_obj.context.get("screen", "")
    topic = request_obj.context.get("topic", "")

    if screen and screen not in VALID_SCREENS:
        raise HTTPException(status_code=400, detail="Invalid screen context")
    if topic and topic not in VALID_TOPICS:
        raise HTTPException(status_code=400, detail="Invalid topic context")

    response = await GreyService.chat(request_obj.message, request_obj.context)
    return response
