#!/usr/bin/env python3
"""
WordPress Backup Monitor Service

This service monitors backup status and provides metrics to Prometheus.
It tracks backup age, size, and success/failure status.
"""

import os
import time
import logging
import subprocess
import psycopg2
from datetime import datetime, timedelta
from prometheus_client import start_http_server, Gauge, Counter, Info
import requests

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Prometheus metrics
backup_status = Gauge('backup_status', 'Backup status (1=failed, 0=success)', ['type'])
backup_timestamp = Gauge('backup_timestamp', 'Last backup timestamp', ['type'])
backup_size = Gauge('backup_size', 'Backup size in bytes', ['type'])
backup_storage_free_percent = Gauge('backup_storage_free_percent', 'Free storage percentage')
backup_duration = Gauge('backup_duration_seconds', 'Backup duration in seconds', ['type'])
backup_errors = Counter('backup_errors_total', 'Total backup errors', ['type', 'error'])

# Database connection parameters
DB_CONFIG = {
    'host': os.getenv('POSTGRES_HOST', 'postgres'),
    'port': os.getenv('POSTGRES_PORT', '5432'),
    'database': os.getenv('POSTGRES_DB', 'wordpress'),
    'user': os.getenv('POSTGRES_USER', 'wordpress'),
    'password': os.getenv('POSTGRES_PASSWORD', 'wordpress_password')
}

# Backup configuration
BACKUP_RETENTION_DAYS = int(os.getenv('BACKUP_RETENTION_DAYS', '30'))
BACKUP_DIR = '/backups'

class BackupMonitor:
    def __init__(self):
        self.prometheus_url = os.getenv('PROMETHEUS_URL', 'http://prometheus:9090')
        
    def check_database_connection(self):
        """Check if database is accessible"""
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            conn.close()
            return True
        except Exception as e:
            logger.error(f"Database connection failed: {e}")
            return False
    
    def get_database_size(self):
        """Get database size in bytes"""
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor()
            cursor.execute("SELECT pg_database_size(current_database());")
            size = cursor.fetchone()[0]
            cursor.close()
            conn.close()
            return size
        except Exception as e:
            logger.error(f"Failed to get database size: {e}")
            return 0
    
    def get_file_system_size(self, path):
        """Get directory size in bytes"""
        try:
            result = subprocess.run(['du', '-sb', path], capture_output=True, text=True)
            if result.returncode == 0:
                return int(result.stdout.split()[0])
            return 0
        except Exception as e:
            logger.error(f"Failed to get filesystem size: {e}")
            return 0
    
    def get_storage_usage(self):
        """Get storage usage percentage"""
        try:
            result = subprocess.run(['df', '/backups'], capture_output=True, text=True)
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                if len(lines) > 1:
                    parts = lines[1].split()
                    if len(parts) >= 5:
                        used = int(parts[2])
                        total = int(parts[1])
                        free_percent = ((total - used) / total) * 100
                        return free_percent
            return 100
        except Exception as e:
            logger.error(f"Failed to get storage usage: {e}")
            return 100
    
    def find_latest_backup(self, backup_type):
        """Find the latest backup file for a given type"""
        backup_pattern = f"{BACKUP_DIR}/{backup_type}_*.gz"
        try:
            result = subprocess.run(['find', BACKUP_DIR, '-name', f"{backup_type}_*.gz", '-type', 'f'], 
                                  capture_output=True, text=True)
            if result.returncode == 0 and result.stdout.strip():
                files = result.stdout.strip().split('\n')
                latest_file = max(files, key=os.path.getctime)
                return latest_file
            return None
        except Exception as e:
            logger.error(f"Failed to find latest backup: {e}")
            return None
    
    def get_backup_info(self, backup_type):
        """Get backup information (timestamp, size, status)"""
        backup_file = self.find_latest_backup(backup_type)
        
        if not backup_file or not os.path.exists(backup_file):
            return {
                'timestamp': 0,
                'size': 0,
                'status': 1,  # failed
                'age': float('inf')
            }
        
        try:
            # Get file modification time
            timestamp = os.path.getmtime(backup_file)
            size = os.path.getsize(backup_file)
            age = time.time() - timestamp
            
            return {
                'timestamp': timestamp,
                'size': size,
                'status': 0,  # success
                'age': age
            }
        except Exception as e:
            logger.error(f"Failed to get backup info: {e}")
            return {
                'timestamp': 0,
                'size': 0,
                'status': 1,  # failed
                'age': float('inf')
            }
    
    def update_metrics(self):
        """Update all Prometheus metrics"""
        try:
            # Check database connection
            if not self.check_database_connection():
                backup_errors.labels(type='database', error='connection').inc()
                return
            
            # Update backup metrics for different types
            backup_types = ['database', 'files']
            
            for backup_type in backup_types:
                info = self.get_backup_info(backup_type)
                
                backup_status.labels(type=backup_type).set(info['status'])
                backup_timestamp.labels(type=backup_type).set(info['timestamp'])
                backup_size.labels(type=backup_type).set(info['size'])
                
                # Log backup age
                if info['age'] != float('inf'):
                    age_hours = info['age'] / 3600
                    logger.info(f"{backup_type} backup age: {age_hours:.1f} hours")
            
            # Update storage metrics
            free_percent = self.get_storage_usage()
            backup_storage_free_percent.set(free_percent)
            
            logger.info(f"Storage free: {free_percent:.1f}%")
            
        except Exception as e:
            logger.error(f"Failed to update metrics: {e}")
            backup_errors.labels(type='system', error='update_metrics').inc()
    
    def run(self):
        """Main monitoring loop"""
        logger.info("Starting backup monitor service")
        
        # Start Prometheus metrics server
        start_http_server(9091)
        logger.info("Prometheus metrics server started on port 9091")
        
        # Main monitoring loop
        while True:
            try:
                self.update_metrics()
                time.sleep(60)  # Update every minute
            except KeyboardInterrupt:
                logger.info("Shutting down backup monitor")
                break
            except Exception as e:
                logger.error(f"Error in monitoring loop: {e}")
                time.sleep(60)

if __name__ == '__main__':
    monitor = BackupMonitor()
    monitor.run()
