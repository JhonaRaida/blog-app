-- ============================================================
-- Blog App - Script de creación de base de datos (MySQL 8)
-- Uso:  mysql -u root -p < database/schema.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS blog_db
  CHARACTER SET utf8mb4          -- utf8mb4 es necesario para guardar emojis
  COLLATE utf8mb4_unicode_ci;

USE blog_db;

-- ---------- Usuarios ----------
CREATE TABLE IF NOT EXISTS users (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(80)  NOT NULL,
  email         VARCHAR(120) NOT NULL UNIQUE,
  password_hash VARCHAR(100) NOT NULL,            -- hash bcrypt, nunca la contraseña real
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------- Posts / entradas ----------
CREATE TABLE IF NOT EXISTS posts (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  author_id  INT          NOT NULL,
  title      VARCHAR(150) NOT NULL,
  content    TEXT         NOT NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_posts_author FOREIGN KEY (author_id)
    REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_posts_created (created_at)
) ENGINE=InnoDB;

-- ---------- Comentarios ----------
CREATE TABLE IF NOT EXISTS comments (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  post_id    INT      NOT NULL,
  author_id  INT      NOT NULL,
  content    VARCHAR(500) NOT NULL,                 -- puede incluir emojis / stickers
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_comments_post   FOREIGN KEY (post_id)   REFERENCES posts(id) ON DELETE CASCADE,
  CONSTRAINT fk_comments_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_comments_post (post_id)
) ENGINE=InnoDB;

-- ---------- Opcional 1: Valoración con estrellas ----------
-- Un usuario solo puede tener UNA valoración por post (se puede cambiar).
CREATE TABLE IF NOT EXISTS ratings (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  post_id    INT NOT NULL,
  user_id    INT NOT NULL,
  stars      TINYINT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ratings_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
  CONSTRAINT fk_ratings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT uq_rating_user_post UNIQUE (post_id, user_id),
  CONSTRAINT ck_rating_stars CHECK (stars BETWEEN 1 AND 5)
) ENGINE=InnoDB;

-- ---------- Opcional 2: Reacciones con emoji en comentarios ----------
-- Un usuario puede poner un mismo emoji una sola vez por comentario.
CREATE TABLE IF NOT EXISTS comment_reactions (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  comment_id INT NOT NULL,
  user_id    INT NOT NULL,
  emoji      VARCHAR(8) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_react_comment FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE,
  CONSTRAINT fk_react_user    FOREIGN KEY (user_id)    REFERENCES users(id)    ON DELETE CASCADE,
  CONSTRAINT uq_reaction UNIQUE (comment_id, user_id, emoji)
) ENGINE=InnoDB;
