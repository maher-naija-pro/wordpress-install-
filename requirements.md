# WordPress Development Environment Requirements

## Overview
This document outlines the requirements for setting up a complete WordPress development environment using Docker and Docker Compose, including PostgreSQL database, Nginx reverse proxy, and Let's Encrypt SSL certificates.

## System Requirements

### Prerequisites
- Docker Engine 24.0+ 
- Docker Compose 2.24+
- Git


### Operating System Support
- Linux (Ubuntu 22.04+ recommended)
- macOS 12.0+
- Windows 10/11 with WSL2


## Core Components

### 1. WordPress
- **Version**: Latest stable WordPress (6.5+)
- **PHP Version**: 8.2 or 8.3
- **Extensions Required**:
  - mysqli
  - pdo_mysql
  - pdo_pgsql
  - gd
  - curl
  - zip
  - intl
  - xml
  - mbstring
  - imagick

### 2. Database - PostgreSQL
- **Version**: PostgreSQL 16+
- **Configuration**:
  - Database name: `wordpress`
  - User: `wordpress`
  - Password: Environment variable controlled
  - Port: 5432 (internal)
  - Data persistence: Docker volume

### 3. Web Server - Nginx
- **Version**: Nginx 1.25+
- **Features**:
  - Reverse proxy configuration
  - SSL termination
  - Static file serving
  - Gzip compression
  - Security headers
  - Rate limiting

### 4. SSL/TLS - Let's Encrypt
- **Certificate Authority**: Let's Encrypt
- **Certbot Version**: 2.5+
- **Certificate Type**: DV (Domain Validated)
- **Auto-renewal**: Enabled via cron job
- **HTTP-01 Challenge**: Supported
- **Wildcard certificates**: Optional

## Docker Configuration

### Docker Compose Services
1. **wordpress**: WordPress application container
2. **postgres**: PostgreSQL database container
3. **nginx**: Nginx reverse proxy container
4. **certbot**: Let's Encrypt certificate management
5. **prometheus**: Metrics collection and alerting
6. **grafana**: Visualization and dashboards
7. **alertmanager**: Alert handling and notifications
8. **backup-monitor**: Custom backup monitoring service
9. **node-exporter**: System metrics collection
10. **cadvisor**: Container metrics collection
11. **postgres-exporter**: Database performance metrics
12. **nginx-exporter**: Web server metrics
13. **webhook**: Notification webhook service

### Docker Image Versions (Latest Stable)
- **WordPress**: `wordpress:6.5-php8.3-fpm`
- **PostgreSQL**: `postgres:16-alpine`
- **Nginx**: `nginx:1.25-alpine`
- **Certbot**: `certbot/certbot:v2.5.0`
- **Prometheus**: `prom/prometheus:latest`
- **Grafana**: `grafana/grafana:latest`
- **Alertmanager**: `prom/alertmanager:latest`
- **Node Exporter**: `prom/node-exporter:latest`
- **cAdvisor**: `gcr.io/cadvisor/cadvisor:latest`
- **PostgreSQL Exporter**: `prometheuscommunity/postgres-exporter:latest`
- **Nginx Exporter**: `nginx/nginx-prometheus-exporter:latest`
- **Webhook**: `adnanh/webhook:latest`

### Volume Requirements
- `wordpress_data`: WordPress files and uploads
- `postgres_data`: PostgreSQL database files
- `nginx_conf`: Nginx configuration files
- `certbot_conf`: SSL certificates and Let's Encrypt data
- `certbot_www`: Webroot for certificate validation
- `prometheus_data`: Prometheus metrics storage
- `grafana_data`: Grafana configuration and dashboards
- `alertmanager_data`: Alertmanager configuration and state

### Network Configuration
- **Network Type**: Custom bridge network
- **Network Names**: 
  - `wordpress_network`: WordPress application services
  - `monitoring_network`: Monitoring and alerting services
- **Internal Communication**: Services communicate within their respective networks
- **Cross-Network Access**: Monitoring services can access WordPress services for metrics collection

## Environment Variables

### Required Environment Variables
```bash
# Database Configuration
POSTGRES_DB=wordpress
POSTGRES_USER=wordpress
POSTGRES_PASSWORD=<secure_password>
POSTGRES_HOST=postgres

# WordPress Configuration
WORDPRESS_DB_HOST=postgres:5432
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=<secure_password>
WORDPRESS_TABLE_PREFIX=wp_

# Domain Configuration
DOMAIN_NAME=yourdomain.com
EMAIL=admin@yourdomain.com

# SSL Configuration
LETSENCRYPT_EMAIL=admin@yourdomain.com

# Monitoring Configuration
GRAFANA_ADMIN_PASSWORD=admin123
SLACK_WEBHOOK_URL=
DISCORD_WEBHOOK_URL=

# SMTP Configuration (for notifications)
SMTP_SERVER=localhost
SMTP_PORT=587
SMTP_USERNAME=
SMTP_PASSWORD=
```

### Optional Environment Variables
```bash
# WordPress Security
WORDPRESS_AUTH_KEY=<generated_key>
WORDPRESS_SECURE_AUTH_KEY=<generated_key>
WORDPRESS_LOGGED_IN_KEY=<generated_key>
WORDPRESS_NONCE_KEY=<generated_key>
WORDPRESS_AUTH_SALT=<generated_salt>
WORDPRESS_SECURE_AUTH_SALT=<generated_salt>
WORDPRESS_LOGGED_IN_SALT=<generated_salt>
WORDPRESS_NONCE_SALT=<generated_salt>

# Performance
WORDPRESS_DEBUG=false
WORDPRESS_DEBUG_LOG=false
```

## Security Requirements

### SSL/TLS Configuration
- **Minimum TLS Version**: 1.2
- **Cipher Suites**: Modern, secure ciphers only
- **HSTS**: Enabled with 1-year max-age
- **Certificate Transparency**: Enabled

### Security Headers
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- X-XSS-Protection: 1; mode=block
- Referrer-Policy: strict-origin-when-cross-origin
- Content-Security-Policy: Strict policy

### Access Control
- Database access: Internal network only
- WordPress admin: IP whitelist (optional)
- File permissions: 644 for files, 755 for directories

## Performance Requirements

### Caching
- **Nginx**: Static file caching
- **WordPress**: Object caching (Redis recommended)
- **Database**: Query optimization

### Resource Limits
- **WordPress Container**: 1GB RAM, 2 CPU cores
- **PostgreSQL Container**: 2GB RAM, 2 CPU cores
- **Nginx Container**: 512MB RAM, 1 CPU core

### Monitoring
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **Alertmanager**: Alert handling and notifications
- **Node Exporter**: System metrics collection
- **cAdvisor**: Container metrics collection
- **PostgreSQL Exporter**: Database performance metrics
- **Nginx Exporter**: Web server metrics
- **Backup Monitor**: Custom backup monitoring service
- Container health checks
- Log aggregation
- Resource usage monitoring
- Real-time alerting and notifications

## Backup Requirements

### Database Backups
- **Frequency**: Daily automated backups
- **Retention**: 30 days
- **Format**: SQL dump files
- **Storage**: Local + cloud storage (optional)

### File Backups
- **Frequency**: Daily automated backups
- **Content**: WordPress files, uploads, themes, plugins
- **Retention**: 30 days
- **Compression**: Gzip compression
- **Incremental**: Weekly full backups, daily incremental
- **Exclusions**: Cache files, temporary files, logs

### Backup Scripts
- **Database Backup**: `scripts/backup-db.sh`
  - Creates timestamped SQL dumps
  - Validates backup integrity
  - Compresses and encrypts files
  - Uploads to cloud storage
- **File Backup**: `scripts/backup-files.sh`
  - Rsync-based incremental backups
  - Preserves file permissions and timestamps
  - Creates compressed archives
  - Excludes unnecessary files

### Recovery Procedures

#### Database Recovery
1. **Stop WordPress Services**
   ```bash
   docker-compose stop wordpress nginx
   ```

2. **Restore Database**
   ```bash
   # List available backups
   ./scripts/list-backups.sh --type=db
   
   # Restore specific backup
   ./scripts/restore-db.sh --backup=2024-01-15_03-00-00.sql.gz
   
   # Verify restoration
   ./scripts/verify-db.sh --backup=2024-01-15_03-00-00.sql.gz
   ```

3. **Restart Services**
   ```bash
   docker-compose up -d
   ```

#### File Recovery
1. **Stop WordPress Services**
   ```bash
   docker-compose stop wordpress nginx
   ```

2. **Restore Files**
   ```bash
   # List available backups
   ./scripts/list-backups.sh --type=files
   
   # Restore specific backup
   ./scripts/restore-files.sh --backup=2024-01-15_03-00-00.tar.gz
   
   # Verify restoration
   ./scripts/verify-files.sh --backup=2024-01-15_03-00-00.tar.gz
   ```

3. **Fix Permissions**
   ```bash
   ./scripts/fix-permissions.sh
   ```

4. **Restart Services**
   ```bash
   docker-compose up -d
   ```

#### Full Site Recovery
1. **Complete Environment Restoration**
   ```bash
   # Stop all services
   docker-compose down
   
   # Restore database and files
   ./scripts/full-restore.sh --date=2024-01-15
   
   # Rebuild containers
   docker-compose up -d --build
   
   # Verify site functionality
   ./scripts/health-check.sh
   ```

### Backup Testing

#### Automated Testing
- **Daily Verification**: Automated backup integrity checks
- **Weekly Restore Tests**: Automated restore to test environment
- **Monthly Full Recovery**: Complete disaster recovery simulation

#### Manual Testing Procedures
1. **Monthly Recovery Test**
   ```bash
   # Create test environment
   ./scripts/create-test-env.sh
   
   # Restore latest backup
   ./scripts/test-restore.sh --latest
   
   # Verify functionality
   ./scripts/test-site-functionality.sh
   
   # Cleanup test environment
   ./scripts/cleanup-test-env.sh
   ```

2. **Backup Validation Checklist**
   - [ ] Database backup is complete and valid
   - [ ] File backup includes all necessary directories
   - [ ] Backup files are not corrupted
   - [ ] Restoration process works without errors
   - [ ] Site functionality is fully restored
   - [ ] Performance is within acceptable limits

## Monitoring and Alerting Requirements

### Prometheus Configuration
- **Metrics Collection**: System, application, and custom metrics
- **Retention**: 200 hours of metrics data
- **Scrape Intervals**: 15-60 seconds depending on metric type
- **Alert Rules**: Comprehensive alerting for system health and backup status
- **Targets**: WordPress, PostgreSQL, Nginx, system resources, and backup processes

### Grafana Dashboards
- **WordPress Backup Dashboard**: Real-time backup monitoring and status
- **System Health Dashboard**: CPU, memory, disk, and network metrics
- **Database Performance Dashboard**: PostgreSQL query performance and connections
- **Web Server Dashboard**: Nginx performance and request metrics
- **Container Dashboard**: Docker container resource usage and health

### Alerting Rules
- **Backup Alerts**:
  - Backup failure notifications
  - Backup age warnings (older than 2 days)
  - Backup size anomalies
  - Storage space low warnings
  - Backup process down alerts
- **System Alerts**:
  - High CPU usage (>80% for 5 minutes)
  - High memory usage (>85% for 5 minutes)
  - Disk space low (>85% usage)
  - Container down alerts
  - WordPress slow response (>2s 95th percentile)
  - Database connection high (>80 connections)
  - SSL certificate expiry warnings

### Notification Channels

- **Discord**: Webhook integration for community notifications



### Monitoring Ports
- **Prometheus**: 9090
- **Grafana**: 3000
- **Alertmanager**: 9093
- **Node Exporter**: 9100
- **cAdvisor**: 8080
- **PostgreSQL Exporter**: 9187
- **Nginx Exporter**: 9113
- **Backup Monitor**: 9091
- **Webhook Service**: 5001


## Development Features

### WordPress Configuration
- **Multisite**: Supported
- **Custom Post Types**: Supported
- **REST API**: Enabled
- **XML-RPC**: Configurable

### Development Tools
- **WP-CLI**: Available in container
- **Debug Mode**: Environment variable controlled
- **Error Logging**: File-based logging
- **Query Monitor**: Recommended plugin

### Latest Version Features (2024)
- **WordPress 6.5+**: Enhanced block editor, improved performance, better accessibility
- **PostgreSQL 16+**: Improved query performance, logical replication enhancements
- **PHP 8.3+**: Better performance, new features like readonly classes
- **Nginx 1.25+**: Enhanced HTTP/3 support, improved security features
- **Docker Compose 2.24+**: Better resource management, improved networking

## Deployment Requirements

### Production Checklist
- [ ] SSL certificates installed and auto-renewing
- [ ] Security headers configured
- [ ] Database backups scheduled
- [ ] File backups scheduled
- [ ] Monitoring stack deployed (Prometheus, Grafana, Alertmanager)
- [ ] Backup monitoring service configured
- [ ] Alert rules configured and tested
- [ ] Notification channels configured (Email, Slack, Discord)
- [ ] Grafana dashboards imported and customized
- [ ] Log rotation configured
- [ ] Firewall rules applied
- [ ] Domain DNS configured
- [ ] Monitoring ports secured
- [ ] Backup verification automated

### Maintenance
- **WordPress Updates**: Automated via WP-CLI
- **Plugin Updates**: Manual or automated
- **Security Updates**: Immediate application
- **Certificate Renewal**: Automated via cron

## File Structure
```
wordpress-docker/
├── docker-compose.yml
├── docker-compose.prod.yml
├── docker-compose.monitoring.yml
├── .env.example
├── .env
├── nginx/
│   ├── nginx.conf
│   ├── default.conf
│   └── ssl.conf
├── wordpress/
│   └── wp-config.php
├── monitoring/
│   ├── prometheus/
│   │   ├── prometheus.yml
│   │   └── rules/
│   │       ├── backup-alerts.yml
│   │       └── system-alerts.yml
│   ├── grafana/
│   │   ├── dashboards/
│   │   │   └── wordpress-backup-dashboard.json
│   │   └── datasources/
│   │       └── prometheus.yml
│   ├── alertmanager/
│   │   └── alertmanager.yml
│   ├── backup-monitor/
│   │   ├── backup_monitor.py
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   └── webhook/
│       ├── hooks.json
│       └── scripts/
│           ├── backup-notification.sh
│           └── critical-alert.sh
├── scripts/
│   ├── init-letsencrypt.sh
│   ├── backup-db.sh
│   ├── backup-files.sh
│   ├── backup-with-monitoring.sh
│   └── setup-monitoring.sh
└── README.md
```

## Installation Steps

1. **Clone Repository**: Get the Docker configuration files
2. **Environment Setup**: Copy and configure `.env` file
3. **Domain Configuration**: Point domain to server IP
4. **SSL Certificate**: Run Let's Encrypt initialization script
5. **Start Services**: Launch with `docker-compose up -d`
6. **WordPress Setup**: Complete initial WordPress installation
7. **Security Hardening**: Apply security configurations
8. **Backup Setup**: Configure automated backups
9. **Monitoring Setup**: Run `./scripts/setup-monitoring.sh`
10. **Grafana Configuration**: Access Grafana at http://biyadin.com:3000 and import dashboards
11. **Alert Configuration**: Configure notification channels in Alertmanager

## Troubleshooting

### Common Issues
- SSL certificate generation failures
- Database connection issues
- File permission problems
- Nginx configuration errors

### Log Locations
- **WordPress**: `/var/log/wordpress/`
- **Nginx**: `/var/log/nginx/`
- **PostgreSQL**: `/var/log/postgresql/`
- **Docker**: `docker logs <container_name>`

## Support and Maintenance

### Documentation
- Docker Compose documentation
- WordPress Codex
- Nginx documentation
- Let's Encrypt documentation

### Updates
- **WordPress**: Monthly updates
- **Plugins**: As needed
- **Docker Images**: Quarterly updates
- **Security Patches**: Immediate

---

**Note**: This configuration is designed for production use. For development environments, some security restrictions may be relaxed. Always test in a staging environment before deploying to production.
