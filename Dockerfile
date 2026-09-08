FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend application and static assets
COPY backend/ /app/

# Expose HTTP port
EXPOSE 8000

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV PORT=8000

# Run FastAPI backend and forensic web portal
CMD [uvicorn, main:app, --host, 0.0.0.0, --port, 8000]
