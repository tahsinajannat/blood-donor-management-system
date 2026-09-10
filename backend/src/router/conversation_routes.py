from fastapi import APIRouter, Depends

from src.schema.chat_schema import CreateConversation
from src.controller.conversation_controller import (
    create_conversation,
    get_my_conversations,
    get_conversation
)

from src.db.db import get_db
from src.utils.dipendencies import get_current_user


router = APIRouter(
    prefix="/conversations",
    tags=["Conversations"]
)


@router.post("/")
async def create_new_conversation(
    data: CreateConversation,
    current_user_id: int = Depends(get_current_user),
    db=Depends(get_db)
):
    return await create_conversation(
        current_user_id=current_user_id,
        other_user_id=data.user_id,
        db=db
    )


@router.get("/")
async def get_conversations(
    current_user_id: int = Depends(get_current_user),
    db=Depends(get_db)
):
    return await get_my_conversations(
        current_user_id=current_user_id,
        db=db
    )


@router.get("/{conversation_id}")
async def get_single_conversation(
    conversation_id: int,
    current_user_id: int = Depends(get_current_user),
    db=Depends(get_db)
):
    return await get_conversation(
        conversation_id=conversation_id,
        current_user_id=current_user_id,
        db=db
    )