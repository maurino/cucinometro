FROM python:3.12-slim

WORKDIR /app

# Installa dipendenze
RUN pip install --no-cache-dir django requests markdown

# Copia i file del progetto
COPY . .

# Applica migrazioni
RUN python manage.py migrate

# Raccogli file statici (se necessario)
RUN python manage.py collectstatic --noinput || true

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

