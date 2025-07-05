FROM python:3.11-slim

LABEL maintainer="ATM Transaction Consumer"
LABEL description="Kafka consumer for ATM transaction messages"

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY atm_consumer.py .

# Create config directory (will be mounted via ConfigMap)
RUN mkdir -p /app/config

# Create non-root user
RUN useradd -m -u 1001 consumer
USER consumer

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD python -c "import kafka; print('OK')" || exit 1

# Command to run the consumer
CMD ["python", "atm_consumer.py"] 