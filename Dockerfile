FROM python:3.11-slim

LABEL maintainer="GitAuditor.io <support@gitauditor.io>"
LABEL description="GitAuditor GitHub Action for security scanning"
LABEL version="1.0.0"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the action script
COPY scan.py .
RUN chmod +x scan.py

# Set the entrypoint
ENTRYPOINT ["python", "/app/scan.py"]