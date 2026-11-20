"""Convierte modelos de base de datos en las respuestas (schemas) que ve la app."""
from app.models.comment import Comment
from app.models.post import Post
from app.models.user import User
from app.schemas.comment import ALLOWED_REACTIONS, CommentOut, ReactionCount
from app.schemas.post import PostOut


def post_to_out(post: Post, current_user: User) -> PostOut:
    stars = [r.stars for r in post.ratings]
    mine = next((r.stars for r in post.ratings if r.user_id == current_user.id), None)
    return PostOut(
        id=post.id,
        title=post.title,
        content=post.content,
        created_at=post.created_at,
        author_id=post.author_id,
        author_name=post.author.name,
        is_mine=post.author_id == current_user.id,
        comment_count=len(post.comments),
        avg_rating=round(sum(stars) / len(stars), 1) if stars else 0.0,
        rating_count=len(stars),
        my_rating=mine,
    )


def comment_to_out(comment: Comment, current_user: User) -> CommentOut:
    reactions = []
    for emoji in ALLOWED_REACTIONS:
        users = [r.user_id for r in comment.reactions if r.emoji == emoji]
        if users:
            reactions.append(
                ReactionCount(emoji=emoji, count=len(users), reacted=current_user.id in users)
            )
    return CommentOut(
        id=comment.id,
        post_id=comment.post_id,
        author_id=comment.author_id,
        author_name=comment.author.name,
        content=comment.content,
        created_at=comment.created_at,
        reactions=reactions,
    )
