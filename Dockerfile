# ---------------------------------------------------------------------
# ETAPA 1: "builder" - Instalar dependencias de CPU
# ---------------------------------------------------------------------
FROM python:3.11-slim-bullseye as builder

# Variables de entorno para optimizar Python
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Instalar dependencias del sistema (libsndfile es necesario)
RUN apt-get update && \
    apt-get install -y --no-install-recommends libsndfile1 && \
    rm -rf /var/lib/apt/lists/*

# Actualizar pip
RUN pip install --no-cache-dir --upgrade pip

# Copiar el archivo de requisitos de CPU
# ¡Este es el archivo correcto para CPU según la documentación que enviaste!
COPY requirements.txt .

# Instalar los paquetes en una carpeta separada
# Esto aprovecha la caché de Docker
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------------------------------------------------------------------
# ETAPA 2: "final" - La imagen de producción
# ---------------------------------------------------------------------
# Empezamos DE NUEVO desde una imagen limpia
FROM python:3.11-slim-bullseye

# Variables de entorno
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Crear un usuario no-root para seguridad
RUN addgroup --system app && adduser --system --ingroup app app

# Instalar la dependencia de sistema (libsndfile)
RUN apt-get update && \
    apt-get install -y --no-install-recommends libsndfile1 && \
    rm -rf /var/lib/apt/lists/*

# Crear los directorios para los volúmenes (según tu README)
# Damos permisos al usuario 'app'
RUN mkdir -p /app/voices /app/reference_audio /app/outputs /app/logs /app/hf_cache && \
    chown -R app:app /app

# Copiar las dependencias instaladas de la etapa 'builder'
COPY --from=builder /install /usr/local

# Copiar TODO el código de la aplicación
COPY . .

# Asignar propiedad de todo el código al usuario 'app'
RUN chown -R app:app /app

# Cambiar al usuario no-root
USER app

# Exponer el puerto (el README menciona 8004 como ejemplo)
EXPOSE 8004

# HEALTHCHECK para que EasyPanel sepa si la app está sana
# (El README menciona /api/ui/initial-data como un buen endpoint)
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8004/api/ui/initial-data || exit 1

# Comando para iniciar el servidor (según tu README)
CMD ["python", "server.py"]
