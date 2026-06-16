#!/bin/bash
# setup-web.sh - Instala y configura el servidor web del blog
# Seguro de reejecutar en el CT de aplicación (Debian 12, 128 MB RAM)
# Ejecutar como root

set -euo pipefail

APP_DIR="/app"
VENV_DIR="${APP_DIR}/venv"
NGINX_CONF="/etc/nginx/sites-available/blog"
SERVICE_FILE="/etc/systemd/system/blog.service"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "${SCRIPT_DIR}")"

echo "==> [1/7] Actualizando paquetes e instalando dependencias del sistema..."
apt-get update -qq
apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip \
    nginx curl wget

echo "==> [2/7] Copiando archivos de la aplicación a ${APP_DIR}..."
mkdir -p "${APP_DIR}/static/fonts"
mkdir -p "${APP_DIR}/templates"

cp "${REPO_DIR}/app/app.py"          "${APP_DIR}/app.py"
cp "${REPO_DIR}/app/requirements.txt" "${APP_DIR}/requirements.txt"
cp -r "${REPO_DIR}/app/templates/."  "${APP_DIR}/templates/"
cp -r "${REPO_DIR}/app/static/."     "${APP_DIR}/static/"

# Placeholders si no existen todavía
[ -f "${APP_DIR}/static/foto.jpg" ]    || touch "${APP_DIR}/static/foto.jpg"
[ -f "${APP_DIR}/static/informe.pdf" ] || touch "${APP_DIR}/static/informe.pdf"

echo "==> [3/7] Descargando fuentes Montserrat (self-hosted, woff2)..."
FONTS_DIR="${APP_DIR}/static/fonts"

# Pesos 300, 400, 600 y 700 (subsets latin)
declare -A FONT_URLS=(
    ["montserrat-300.woff2"]="https://fonts.gstatic.com/s/montserrat/v26/JTUHjIg1_i6t8kCHKm4532VJOt5-QNFgpCs16Hw5aXo.woff2"
    ["montserrat-400.woff2"]="https://fonts.gstatic.com/s/montserrat/v26/JTUHjIg1_i6t8kCHKm4532VJOt5-QNFgpCtr6Hw5aXo.woff2"
    ["montserrat-600.woff2"]="https://fonts.gstatic.com/s/montserrat/v26/JTUHjIg1_i6t8kCHKm4532VJOt5-QNFgpCu170w5aXo.woff2"
    ["montserrat-700.woff2"]="https://fonts.gstatic.com/s/montserrat/v26/JTUHjIg1_i6t8kCHKm4532VJOt5-QNFgpCuM70w5aXo.woff2"
    ["montserrat-300i.woff2"]="https://fonts.gstatic.com/s/montserrat/v26/JTUFjIg1_i6t8kCHKm459Wx7xQYXK0vOoz6jqyR9WXR0poGK.woff2"
    ["montserrat-600i.woff2"]="https://fonts.gstatic.com/s/montserrat/v26/JTUFjIg1_i6t8kCHKm459Wx7xQYXK0vOoz6jq6R9WXR0poGK.woff2"
)

for FILENAME in "${!FONT_URLS[@]}"; do
    DEST="${FONTS_DIR}/${FILENAME}"
    if [ ! -f "${DEST}" ] || [ ! -s "${DEST}" ]; then
        echo "   Descargando ${FILENAME}..."
        wget -q -O "${DEST}" "${FONT_URLS[$FILENAME]}" || \
            echo "   ADVERTENCIA: no se pudo descargar ${FILENAME}. Descargarlo manualmente."
    else
        echo "   ${FILENAME} ya existe, omitiendo."
    fi
done

echo "==> [4/7] Creando entorno virtual e instalando paquetes Python..."
if [ ! -d "${VENV_DIR}" ]; then
    python3 -m venv "${VENV_DIR}"
fi
"${VENV_DIR}/bin/pip" install --quiet --upgrade pip
"${VENV_DIR}/bin/pip" install --quiet -r "${APP_DIR}/requirements.txt"

echo "==> [5/7] Configurando permisos..."
chown -R www-data:www-data "${APP_DIR}"
chmod -R 755 "${APP_DIR}"

echo "==> [6/7] Instalando configuración de Nginx..."
cp "${REPO_DIR}/config/nginx-blog.conf" "${NGINX_CONF}"
ln -sf "${NGINX_CONF}" /etc/nginx/sites-enabled/blog
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx || systemctl start nginx

echo "==> [7/7] Instalando y arrancando el servicio systemd..."
cp "${REPO_DIR}/config/blog.service" "${SERVICE_FILE}"
systemctl daemon-reload
systemctl enable blog
systemctl restart blog

echo ""
echo "==========================================="
echo " Blog instalado correctamente."
echo " Verificá el estado con:"
echo "   systemctl status blog"
echo "   systemctl status nginx"
echo "==========================================="
