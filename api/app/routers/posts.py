from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.post import Post, Rating
from app.models.user import User
from app.schemas.post import PostCreate, PostOut, RatingIn
from app.serializers import post_to_out

router = APIRouter(prefix="/posts", tags=["Posts"])


def _get_post_or_404(db: Session, post_id: int) -> Post:
    post = db.get(Post, post_id)
    if post is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "La publicación no existe")
    return post


@router.get("", response_model=list[PostOut])
def list_posts(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    """Posts de todos los usuarios (propios y ajenos), del más nuevo al más viejo."""
    posts = db.scalars(select(Post).order_by(Post.created_at.desc(), Post.id.desc())).all()
    return [post_to_out(p, user) for p in posts]


@router.get("/mine", response_model=list[PostOut])
def my_posts(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    posts = db.scalars(
        select(Post).where(Post.author_id == user.id).order_by(Post.created_at.desc(), Post.id.desc())
    ).all()
    return [post_to_out(p, user) for p in posts]


@router.get("/{post_id}", response_model=PostOut)
def get_post(post_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return post_to_out(_get_post_or_404(db, post_id), user)


@router.post("", response_model=PostOut, status_code=status.HTTP_201_CREATED)
def create_post(data: PostCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    post = Post(author_id=user.id, title=data.title.strip(), content=data.content.strip())
    db.add(post)
    db.commit()
    db.refresh(post)
    return post_to_out(post, user)


@router.delete("/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_post(post_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    post = _get_post_or_404(db, post_id)
    if post.author_id != user.id:  # control de acceso: solo el autor puede borrar
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No puedes borrar publicaciones de otros")
    db.delete(post)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ---------- Opcional 1: valoración con estrellas ----------
@router.put("/{post_id}/rating", response_model=PostOut)
def rate_post(
    post_id: int,
    data: RatingIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Crea o cambia la valoración del usuario actual para este post."""
    post = _get_post_or_404(db, post_id)
    if post.author_id == user.id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "No puedes valorar tu propia publicación")
    rating = db.scalar(select(Rating).where(Rating.post_id == post_id, Rating.user_id == user.id))
    if rating:
        rating.stars = data.stars
    else:
        db.add(Rating(post_id=post_id, user_id=user.id, stars=data.stars))
    db.commit()
    db.refresh(post)
    return post_to_out(post, user)
