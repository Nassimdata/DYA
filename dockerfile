# Image Python 3.11 (meilleure compatibilité avec vos packages)
FROM python:3.11-slim

# Installer les dépendances système
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Dossier de travail
WORKDIR /app

# Copier requirements
COPY requirements.txt .

# Mettre à jour pip, setuptools, wheel
RUN pip install --upgrade pip setuptools wheel

# Installer Cython d'abord (nécessaire pour certains packages)
RUN pip install Cython

# Installer les dépendances
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code
COPY . .

# Variable d'environnement pour Azure (important!)
ENV PORT=8000
ENV PYTHONUNBUFFERED=1

# Exposer le port
EXPOSE 8000

# Healthcheck pour Azure
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/', timeout=5)" || exit 1

# Commande de démarrage avec gunicorn
# Adaptez "app:app" selon votre fichier (si c'est main.py:app alors mettez "main:app")
CMD gunicorn --bind 0.0.0.0:$PORT \
    --workers 2 \
    --threads 4 \
    --timeout 300 \
    --access-logfile - \
    --error-logfile - \
    --log-level info \
    app:app
