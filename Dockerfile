FROM python:3.12-slim

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

# Fuentes placeholder para que CSS no rompa (en local no se descargan)
RUN mkdir -p static/fonts

EXPOSE 5000

# En local corre el server de desarrollo de Flask (no Gunicorn)
CMD ["python", "app.py"]
