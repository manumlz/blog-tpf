-- Schema del blog personal
-- Seguro de reejecutar: usa IF NOT EXISTS

CREATE DATABASE IF NOT EXISTS blog
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE blog;

CREATE TABLE IF NOT EXISTS posts (
    id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    titulo          VARCHAR(200)    NOT NULL,
    contenido       TEXT            NOT NULL,
    fecha_creacion  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
