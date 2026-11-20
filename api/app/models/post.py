from datetime import datetime

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, String, Text, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Post(Base):
    __tablename__ = "posts"

    id: Mapped[int] = mapped_column(primary_key=True)
    author_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    title: Mapped[str] = mapped_column(String(150))
    content: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    author = relationship("User", back_populates="posts")
    comments = relationship("Comment", back_populates="post", cascade="all, delete-orphan")
    ratings = relationship("Rating", back_populates="post", cascade="all, delete-orphan")


class Rating(Base):
    """Opcional 1: valoración de 1 a 5 estrellas (una por usuario y post)."""

    __tablename__ = "ratings"
    __table_args__ = (
        UniqueConstraint("post_id", "user_id", name="uq_rating_user_post"),
        CheckConstraint("stars BETWEEN 1 AND 5", name="ck_rating_stars"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    post_id: Mapped[int] = mapped_column(ForeignKey("posts.id", ondelete="CASCADE"))
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    stars: Mapped[int]
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    post = relationship("Post", back_populates="ratings")
