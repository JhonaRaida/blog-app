from datetime import datetime

from pydantic import BaseModel, Field

# Reacciones permitidas (lista blanca): evita guardar texto arbitrario como "emoji"
ALLOWED_REACTIONS = ["👍", "❤️", "😂", "😮", "😢", "🔥"]


class CommentCreate(BaseModel):
    content: str = Field(min_length=1, max_length=500)


class ReactionIn(BaseModel):
    emoji: str


class ReactionCount(BaseModel):
    emoji: str
    count: int
    reacted: bool  # ¿el usuario actual ya usó este emoji?


class CommentOut(BaseModel):
    id: int
    post_id: int
    author_id: int
    author_name: str
    content: str
    created_at: datetime
    reactions: list[ReactionCount]
