from datetime import datetime

from pydantic import BaseModel, Field


class PostCreate(BaseModel):
    title: str = Field(min_length=3, max_length=150)
    content: str = Field(min_length=1, max_length=10000)


class PostOut(BaseModel):
    id: int
    title: str
    content: str
    created_at: datetime
    author_id: int
    author_name: str
    is_mine: bool
    comment_count: int
    avg_rating: float
    rating_count: int
    my_rating: int | None = None


class RatingIn(BaseModel):
    stars: int = Field(ge=1, le=5)
