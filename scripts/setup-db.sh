#!/bin/bash
# setup-db.sh - Configura la base de datos del blog
# Seguro de reejecutar: todas las sentencias son idempotentes (IF NOT EXISTS)
# Ejecutar como root en el CT de MariaDB (172.16.90.203)

set -euo pipefail

DB_HOST="localhost"
DB_ROOT_USER="root"
# Ingresá la contraseña de root de MariaDB cuando se solicite:
# mysql -u root -p < /ruta/a/setup-db.sh
# O definila aquí si el script corre desatendido (no recomendado en producción):
# DB_ROOT_PASS="tu_password_root"

DB_NAME="blog"
DB_USER="bloguser"
DB_PASS="BlogPass2024!"
SCHEMA_FILE="$(dirname "$0")/../db/schema.sql"

echo "==> Creando base de datos y usuario (si no existen)..."

mysql -u "${DB_ROOT_USER}" -p <<EOF
-- Base de datos
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Usuario (solo si no existe)
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';

-- Permisos mínimos necesarios
GRANT SELECT, INSERT, UPDATE, DELETE ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

echo "==> Aplicando schema..."
mysql -u "${DB_ROOT_USER}" -p "${DB_NAME}" < "${SCHEMA_FILE}"

echo "==> Listo. Base de datos '${DB_NAME}' y usuario '${DB_USER}' configurados."
