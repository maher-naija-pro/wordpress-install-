FROM python:3.11-alpine

# Install required packages
RUN apk add --no-cache \
    mysql-client \
    rsync \
    gzip \
    tar

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY backup_monitor.py .

# Create backup directory
RUN mkdir -p /backups

# Expose metrics port
EXPOSE 9091

# Run the backup monitor
CMD ["python", "backup_monitor.py"]
