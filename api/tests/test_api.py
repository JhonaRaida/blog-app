import os

# Las pruebas usan SQLite en memoria/archivo temporal para no depender de MySQL
os.environ["DATABASE_URL"] = "sqlite:///./test_blog.db"
os.environ["SECRET_KEY"] = "test-secret-key-de-pruebas-con-32-caracteres"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from app.core.database import Base, engine  # noqa: E402
from app.main import app  # noqa: E402

client = TestClient(app)


@pytest.fixture(autouse=True)
def clean_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield


def register(name="Ana", email="ana@test.com", password="clave1234"):
    r = client.post("/auth/register", json={"name": name, "email": email, "password": password})
    return r


def auth(token):
    return {"Authorization": f"Bearer {token}"}


def token_for(name, email):
    return register(name, email).json()["access_token"]


# ---------- Autenticación ----------
def test_register_and_login():
    r = register()
    assert r.status_code == 201
    assert r.json()["user"]["email"] == "ana@test.com"
    r = client.post("/auth/login", json={"email": "ana@test.com", "password": "clave1234"})
    assert r.status_code == 200 and r.json()["access_token"]


def test_duplicate_email_rejected():
    register()
    assert register().status_code == 409


def test_wrong_password_rejected():
    register()
    r = client.post("/auth/login", json={"email": "ana@test.com", "password": "otra12345"})
    assert r.status_code == 401


def test_weak_password_rejected():
    assert register(password="soloLetras").status_code == 422
    assert register(password="1234").status_code == 422


def test_password_is_hashed_in_db():
    from sqlalchemy import select
    from app.core.database import SessionLocal
    from app.models.user import User

    register()
    with SessionLocal() as db:
        u = db.scalar(select(User))
        assert u.password_hash != "clave1234" and u.password_hash.startswith("$2")


def test_protected_routes_need_token():
    assert client.get("/posts").status_code == 401
    assert client.get("/posts", headers=auth("token-falso")).status_code == 401


# ---------- Posts ----------
def test_create_and_list_posts_own_and_others():
    t1, t2 = token_for("Ana", "a@t.com"), token_for("Beto", "b@t.com")
    client.post("/posts", json={"title": "Post de Ana", "content": "hola"}, headers=auth(t1))
    client.post("/posts", json={"title": "Post de Beto", "content": "mundo"}, headers=auth(t2))
    all_posts = client.get("/posts", headers=auth(t1)).json()
    assert len(all_posts) == 2
    mine = client.get("/posts/mine", headers=auth(t1)).json()
    assert len(mine) == 1 and mine[0]["title"] == "Post de Ana" and mine[0]["is_mine"]


def test_only_author_can_delete():
    t1, t2 = token_for("Ana", "a@t.com"), token_for("Beto", "b@t.com")
    pid = client.post("/posts", json={"title": "Mio", "content": "x"}, headers=auth(t1)).json()["id"]
    assert client.delete(f"/posts/{pid}", headers=auth(t2)).status_code == 403
    assert client.delete(f"/posts/{pid}", headers=auth(t1)).status_code == 204
    assert client.get(f"/posts/{pid}", headers=auth(t1)).status_code == 404


# ---------- Comentarios ----------
def test_comments_create_and_read():
    t1, t2 = token_for("Ana", "a@t.com"), token_for("Beto", "b@t.com")
    pid = client.post("/posts", json={"title": "Titulo", "content": "x"}, headers=auth(t1)).json()["id"]
    r = client.post(f"/posts/{pid}/comments", json={"content": "Buen post 😀"}, headers=auth(t2))
    assert r.status_code == 201
    lst = client.get(f"/posts/{pid}/comments", headers=auth(t1)).json()
    assert len(lst) == 1 and lst[0]["author_name"] == "Beto" and "😀" in lst[0]["content"]
    assert client.get(f"/posts/{pid}", headers=auth(t1)).json()["comment_count"] == 1


def test_comment_on_missing_post_404():
    t = token_for("Ana", "a@t.com")
    assert client.post("/posts/99/comments", json={"content": "hola"}, headers=auth(t)).status_code == 404


# ---------- Opcional 1: estrellas ----------
def test_rating_average_and_update():
    t1, t2, t3 = (token_for("Ana", "a@t.com"), token_for("Beto", "b@t.com"), token_for("Carla", "c@t.com"))
    pid = client.post("/posts", json={"title": "Titulo", "content": "x"}, headers=auth(t1)).json()["id"]
    client.put(f"/posts/{pid}/rating", json={"stars": 5}, headers=auth(t2))
    r = client.put(f"/posts/{pid}/rating", json={"stars": 2}, headers=auth(t3)).json()
    assert r["avg_rating"] == 3.5 and r["rating_count"] == 2 and r["my_rating"] == 2
    # B cambia su voto de 5 a 4: no se duplica
    r = client.put(f"/posts/{pid}/rating", json={"stars": 4}, headers=auth(t2)).json()
    assert r["rating_count"] == 2 and r["avg_rating"] == 3.0


def test_rating_validation():
    t1, t2 = token_for("Ana", "a@t.com"), token_for("Beto", "b@t.com")
    pid = client.post("/posts", json={"title": "Titulo", "content": "x"}, headers=auth(t1)).json()["id"]
    assert client.put(f"/posts/{pid}/rating", json={"stars": 6}, headers=auth(t2)).status_code == 422
    assert client.put(f"/posts/{pid}/rating", json={"stars": 0}, headers=auth(t2)).status_code == 422
    # no puedes valorar tu propio post
    assert client.put(f"/posts/{pid}/rating", json={"stars": 5}, headers=auth(t1)).status_code == 400


# ---------- Opcional 2: reacciones ----------
def test_reaction_toggle():
    t1, t2 = token_for("Ana", "a@t.com"), token_for("Beto", "b@t.com")
    pid = client.post("/posts", json={"title": "Titulo", "content": "x"}, headers=auth(t1)).json()["id"]
    cid = client.post(f"/posts/{pid}/comments", json={"content": "hola"}, headers=auth(t1)).json()["id"]
    r = client.put(f"/comments/{cid}/reactions", json={"emoji": "❤️"}, headers=auth(t2)).json()
    assert r["reactions"] == [{"emoji": "❤️", "count": 1, "reacted": True}]
    client.put(f"/comments/{cid}/reactions", json={"emoji": "❤️"}, headers=auth(t1))
    lst = client.get(f"/posts/{pid}/comments", headers=auth(t1)).json()
    assert lst[0]["reactions"][0]["count"] == 2 and lst[0]["reactions"][0]["reacted"] is True
    # quitar la reacción
    r = client.put(f"/comments/{cid}/reactions", json={"emoji": "❤️"}, headers=auth(t2)).json()
    assert r["reactions"][0]["count"] == 1 and r["reactions"][0]["reacted"] is False


def test_reaction_not_allowed():
    t = token_for("Ana", "a@t.com")
    pid = client.post("/posts", json={"title": "Titulo", "content": "x"}, headers=auth(t)).json()["id"]
    cid = client.post(f"/posts/{pid}/comments", json={"content": "hola"}, headers=auth(t)).json()["id"]
    assert client.put(f"/comments/{cid}/reactions", json={"emoji": "texto"}, headers=auth(t)).status_code == 422
