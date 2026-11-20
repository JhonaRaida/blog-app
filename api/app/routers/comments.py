from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.comment import Comment, CommentReaction
from app.models.post import Post
from app.models.user import User
from app.schemas.comment import ALLOWED_REACTIONS, CommentCreate, CommentOut, ReactionIn
from app.serializers import comment_to_out

router = APIRouter(tags=["Comentarios"])


@router.get("/posts/{post_id}/comments", response_model=list[CommentOut])
def list_comments(post_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    if db.get(Post, post_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "La publicación no existe")
    comments = db.scalars(
        select(Comment).where(Comment.post_id == post_id).order_by(Comment.created_at, Comment.id)
    ).all()
    return [comment_to_out(c, user) for c in comments]


@router.post("/posts/{post_id}/comments", response_model=CommentOut, status_code=status.HTTP_201_CREATED)
def create_comment(
    post_id: int,
    data: CommentCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    if db.get(Post, post_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "La publicación no existe")
    content = data.content.strip()
    if not content:
        raise HTTPException(422, "El comentario no puede estar vacío")
    comment = Comment(post_id=post_id, author_id=user.id, content=content)
    db.add(comment)
    db.commit()
    db.refresh(comment)
    return comment_to_out(comment, user)


# ---------- Opcional 2: reacciones con emoji ----------
@router.put("/comments/{comment_id}/reactions", response_model=CommentOut)
def toggle_reaction(
    comment_id: int,
    data: ReactionIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Si el usuario ya había puesto ese emoji lo quita; si no, lo agrega."""
    comment = db.get(Comment, comment_id)
    if comment is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "El comentario no existe")
    if data.emoji not in ALLOWED_REACTIONS:
        raise HTTPException(422, "Reacción no permitida")
    existing = db.scalar(
        select(CommentReaction).where(
            CommentReaction.comment_id == comment_id,
            CommentReaction.user_id == user.id,
            CommentReaction.emoji == data.emoji,
        )
    )
    if existing:
        db.delete(existing)
    else:
        db.add(CommentReaction(comment_id=comment_id, user_id=user.id, emoji=data.emoji))
    db.commit()
    db.refresh(comment)
    return comment_to_out(comment, user)
