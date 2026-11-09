from fastapi import APIRouter, Depends, Query

from src.schema.chat_schema import SendMessage
from src.controller.message_controller import (
    send_message,
    get_messages
)

from src.db.db import get_db
from src.utils.dipendencies import get_current_user


router = APIRouter(
    prefix="/conversations",
    tags=["Messages"]
)


@router.post("/{conversation_id}/messages")
async def create_message(
    conversation_id: int,
    data: SendMessage,
    current_user_id: int = Depends(get_current_user),
    db=Depends(get_db)
):
    return await send_message(
        conversation_id=conversation_id,
        current_user_id=current_user_id,
        message_text=data.message,
        db=db
    )


@router.get("/{conversation_id}/messages")
async def conversation_messages(
    conversation_id: int,
    page: int = Query(default=1, ge=1),
    items_per_page: int = Query(default=20, ge=1, le=100),
    current_user_id: int = Depends(get_current_user),
    db=Depends(get_db)
):
    return await get_messages(
        conversation_id=conversation_id,
        current_user_id=current_user_id,
        db=db,
        page=page,
        items_per_page=items_per_page
    )