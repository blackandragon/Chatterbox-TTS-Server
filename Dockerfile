# 1. Usar la imagen de Python completa, que ya incluye build-essential
FROM python:3.11-bullseye

# Variables de entorno
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive
ENV HF_HOME=/app/hf_cache

# 2. Instalar TODAS las dependencias del sistema necesarias para compilar
#    ¡La clave aquí es python3-dev!
RUN apt-get update && apt-get install -y --no-install-recommends \
    libsndfile1 \
    ffmpeg \
    cmake \
    python3-dev \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. Configurar el directorio de trabajo
WORKDIR /app

# 4. Copiar y instalar los requisitos de Python
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copiar el resto de la aplicación
COPY . .

# 6. Crear los directorios para los volúmenes
#    (Usando /app/... como en el README)
RUN mkdir -p /app/voices /app/reference_audio /app/outputs /app/logs /app/hf_cache

# 7. Crear un usuario no-root por seguridad
RUN addgroup --system app && adduser --system --ingroup app app
RUN chown -R app:app /app

# 8. Cambiar al usuario no-root
USER app

# 9. Exponer el puerto
EXPOSE 8004

# 10. HEALTHCHECK
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8004/api/ui/initial-data || exit 1

# 11. Comando para iniciar
CMD ["python", "server.py"]
