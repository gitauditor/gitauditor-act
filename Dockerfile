FROM python:3.11-slim

LABEL maintainer="GitAuditor.io <support@gitauditor.io>"
LABEL description="GitAuditor GitHub Action for git posture scanning"
LABEL org.opencontainers.image.source="https://github.com/gitauditor/gitauditor-act"
LABEL org.opencontainers.image.vendor="GitAuditor.io"
LABEL org.opencontainers.image.title="GitAuditor Posture Scan Action"
LABEL org.opencontainers.image.description="Automated git posture scanning for GitHub repositories"

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

# Copy the action script and version utilities
COPY scan.py version.py VERSION ./
RUN chmod +x scan.py

# Set the entrypoint
ENTRYPOINT ["python", "/app/scan.py"]