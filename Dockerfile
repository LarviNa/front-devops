# Stage 1: Builder
FROM python:3.9-slim AS builder

WORKDIR /app

# Instalar dependencias del sistema necesarias para construir paquetes (si las hay)
RUN apt-get update && apt-get install -y --no-install-recommends gcc build-essential \
    && rm -rf /var/lib/apt/lists/*

# Crear entorno virtual
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copiar requirements y dependencias
COPY requirements.txt .
# Limpieza de capas: instalar dependencias sin guardar cache
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# Stage 2: Runtime
FROM python:3.9-slim

WORKDIR /app

# Copiar el entorno virtual del builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Crear usuario no root por seguridad
RUN addgroup --system appgroup && adduser --system --group appuser

# Copiar código fuente
COPY . .

# Ajustar permisos para el usuario no root
RUN chown -R appuser:appgroup /app

# Cambiar al usuario no root
USER appuser

# Variables de entorno (pueden ser sobrescritas por Docker Compose o ECS)
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

# Exponer el puerto
EXPOSE 5000

# Comando para iniciar la aplicación (se agrega gunicorn para producción)
CMD ["gunicorn", "-b", "0.0.0.0:5000", "app:app"]
