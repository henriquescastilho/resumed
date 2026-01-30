from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Optional, List, Dict
from app.api.deps import get_current_user
from app.models.user import User
from app.services.grey_service import GreyService

router = APIRouter()

class GreyMessageRequest(BaseModel):
    message: str
    context: Dict[str, str] = {} # screen, topic

class FlashcardDTO(BaseModel):
    front: str
    back: str

class GreyResponse(BaseModel):
    answer_markdown: str
    flashcard: Optional[FlashcardDTO] = None
    tags: List[str] = []

@router.post("/message", response_model=GreyResponse)
async def send_message(
    request: GreyMessageRequest,
    current_user: User = Depends(get_current_user)
):
    # Enrich context with User specifics (e.g. weak areas from DB)
    # For MVP, pass through
    
    response = await GreyService.chat(request.message, request.context)
    return response
