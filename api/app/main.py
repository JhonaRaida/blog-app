from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import models  # noqa: F401  (registra las tablas)
from app.core.database import Base, engine
from app.routers import auth, comments, posts

app = FastAPI(title="Blog API", version="1.0.0", description="API del blog (Flutter + FastAPI + MySQL)")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ajustar en producción
    allow_methods=["*"],
    allow_headers=["*"],
)

# Si las tablas no existen (por ejemplo en pruebas con SQLite) se crean solas.
# En MySQL se recomienda usar database/schema.sql.
Base.metadata.create_all(bind=engine)

app.include_router(auth.router)
app.include_router(posts.router)
app.include_router(comments.router)


@app.get("/", tags=["Estado"])
def health():
    return {"status": "ok", "app": "Blog API"}
