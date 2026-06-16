"""
Blog personal - Victor Manuel Miranda López
UTN FRT - Virtualización y Consolidación de Servidores
"""

import os
from datetime import timedelta
from flask import Flask, render_template, request, redirect, url_for, flash
import pymysql
import pymysql.cursors

app = Flask(__name__)
app.secret_key = "cambiar_en_produccion_por_valor_aleatorio"

_MESES = [
    "", "enero", "febrero", "marzo", "abril", "mayo", "junio",
    "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre",
]

# MariaDB almacena CURRENT_TIMESTAMP en UTC; Argentina es UTC-3 (sin DST desde 2008)
_TZ_OFFSET = timedelta(hours=-3)

@app.template_filter("fecha_es")
def fecha_es(dt):
    """Convierte UTC a hora argentina y formatea como '15 de junio de 2026, 21:14'."""
    dt_local = dt + _TZ_OFFSET
    return f"{dt_local.day} de {_MESES[dt_local.month]} de {dt_local.year}, {dt_local.strftime('%H:%M')}"

# --- Configuración de la base de datos ---
# DB_HOST puede sobreescribirse con variable de entorno (útil en Docker local)
DB_CONFIG = {
    "host": os.environ.get("DB_HOST", "172.16.90.203"),
    "user": "bloguser",
    "password": "BlogPass2024!",
    "database": "blog",
    "charset": "utf8mb4",
    "cursorclass": pymysql.cursors.DictCursor,
    "connect_timeout": 5,
}


def get_connection():
    """Abre y retorna una conexión a MariaDB."""
    return pymysql.connect(**DB_CONFIG)


def get_posts():
    """Obtiene todos los posts ordenados por fecha descendente."""
    try:
        conn = get_connection()
        with conn.cursor() as cursor:
            cursor.execute(
                "SELECT id, titulo, contenido, fecha_creacion "
                "FROM posts ORDER BY fecha_creacion DESC"
            )
            return cursor.fetchall(), None
    except pymysql.Error as e:
        return [], f"No se pudo conectar a la base de datos: {e}"
    finally:
        try:
            conn.close()
        except Exception:
            pass


def insert_post(titulo, contenido):
    """Inserta un nuevo post. Retorna None si tuvo éxito, mensaje de error si no."""
    try:
        conn = get_connection()
        with conn.cursor() as cursor:
            cursor.execute(
                "INSERT INTO posts (titulo, contenido) VALUES (%s, %s)",
                (titulo, contenido),
            )
        conn.commit()
        return None
    except pymysql.Error as e:
        return f"Error al guardar el post: {e}"
    finally:
        try:
            conn.close()
        except Exception:
            pass


@app.route("/", methods=["GET", "POST"])
def index():
    errores = {}

    if request.method == "POST":
        titulo = request.form.get("titulo", "").strip()
        contenido = request.form.get("contenido", "").strip()

        # Validación básica
        if not titulo:
            errores["titulo"] = "El título es obligatorio."
        elif len(titulo) > 200:
            errores["titulo"] = "El título no puede superar los 200 caracteres."

        if not contenido:
            errores["contenido"] = "El contenido es obligatorio."

        if not errores:
            db_error = insert_post(titulo, contenido)
            if db_error:
                flash(db_error, "error")
            else:
                flash("Entrada publicada correctamente.", "success")
                return redirect(url_for("index"))
        else:
            # Re-renderiza con errores y los valores ingresados
            posts, db_error = get_posts()
            if db_error:
                flash(db_error, "error")
            return render_template(
                "index.html",
                posts=posts,
                errores=errores,
                form_titulo=titulo,
                form_contenido=contenido,
            )

    # GET
    posts, db_error = get_posts()
    if db_error:
        flash(db_error, "error")

    return render_template("index.html", posts=posts, errores={})


if __name__ == "__main__":
    debug = os.environ.get("FLASK_ENV") == "development"
    app.run(host="0.0.0.0", port=5000, debug=debug)
