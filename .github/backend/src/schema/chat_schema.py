from pydantic import BaseModel


class CreateConversation(BaseModel):
    user_id: int


class SendMessage(BaseModel):
    message: str