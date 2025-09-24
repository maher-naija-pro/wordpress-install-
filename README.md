# WordPress Docker Development Environment

A complete WordPress development environment with PostgreSQL, Nginx, SSL certificates, and comprehensive monitoring using Docker Compose.

## Features

- **WordPress 6.5+** with PHP 8.3
- **PostgreSQL 16** database
- **Nginx** reverse proxy with SSL termination
- **Let's Encrypt** SSL certificates
- **Prometheus** metrics collection
- **Grafana** dashboards and visualization
- **Alertmanager** for alerting
- **Automated backups** with monitoring
- **Security headers** and rate limiting
- **Health checks** for all services

## Prerequisites

Before starting, ensure you have Docker and Docker Compose installed on your Ubuntu system.

### Install Docker and Docker Compose

**Option 1: Use our automated installation script (Recommended)**
```bash
# Run the Docker installation script
./install-docker.sh
```

**Option 2: Manual installation**
Follow the [official Docker installation guide](https://docs.docker.com/engine/install/ubuntu/) for Ubuntu.

## Quick Start

1. **Clone and setup environment:**
   ```bash
   git clone <repository-url>
   cd wordpress-docker
   cp env.example .env
   ```

2. **Install Docker (if not already installed):**
   ```bash
   ./install-docker.sh
   ```

3. **Configure environment variables:**
   Edit `.env` file with your settings:
   ```bash
   DOMAIN_NAME=yourdomain.com
   LETSENCRYPT_EMAIL=admin@yourdomain.com
   POSTGRES_PASSWORD=your_secure_password
   GRAFANA_ADMIN_PASSWORD=your_grafana_password
   ```

4. **Start the environment:**
   ```bash
   # Start all services
   docker-compose up -d
   
   # Initialize SSL certificates (replace with your domain)
   ./scripts/init-letsencrypt.sh
   
   # Setup monitoring
   ./scripts/setup-monitoring.sh
   ```

4. **Access services:**
   - WordPress: https://yourdomain.com
   - Grafana: http://localhost:3000
   - Prometheus: http://localhost:9090
   - Alertmanager: http://localhost:9093

## Services

### Core Services
- **wordpress**: WordPress application with PHP-FPM
- **postgres**: PostgreSQL 16 database
- **nginx**: Nginx reverse proxy with SSL
- **certbot**: Let's Encrypt certificate management

### Monitoring Services
- **prometheus**: Metrics collection and alerting
- **grafana**: Visualization and dashboards
- **alertmanager**: Alert handling and notifications
- **node-exporter**: System metrics
- **cadvisor**: Container metrics
- **postgres-exporter**: Database metrics
- **nginx-exporter**: Web server metrics
- **backup-monitor**: Backup monitoring service

## Backup System

Automated daily backups with monitoring:

```bash
# Manual backup
./scripts/backup-with-monitoring.sh

# Database only
./scripts/backup-db.sh

# Files only
./scripts/backup-files.sh
```

Backups are stored in `/backups` directory and automatically cleaned up after 30 days.

## Monitoring

### Grafana Dashboards
- WordPress Backup Dashboard
- System Health Dashboard
- Database Performance Dashboard
- Web Server Dashboard
- Container Dashboard

### Alerting
Configured alerts for:
- Backup failures and age
- High CPU/memory usage
- Disk space low
- Container down
- SSL certificate expiry
- Database connection issues

## Security Features

- SSL/TLS encryption with Let's Encrypt
- Security headers (HSTS, XSS protection, etc.)
- Rate limiting
- File permission restrictions
- Database access controls
- Firewall-ready configuration

## Development

### WordPress Configuration
- Debug mode controlled by environment variables
- WP-CLI available in container
- Custom post types supported
- REST API enabled
- Multisite supported

### File Structure
```
wordpress-docker/
├── docker-compose.yml          # Main compose file
├── env.example                 # Environment template
├── nginx/                      # Nginx configurations
├── wordpress/                  # WordPress config
├── monitoring/                 # Monitoring stack
├── scripts/                    # Backup and setup scripts
└── backups/                    # Backup storage
```

## Maintenance

### Updates
```bash
# Update WordPress
docker-compose exec wordpress wp core update

# Update plugins
docker-compose exec wordpress wp plugin update --all

# Update Docker images
docker-compose pull
docker-compose up -d
```

### Logs
```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs wordpress
docker-compose logs nginx
docker-compose logs postgres
```

## Troubleshooting

### Common Issues

1. **SSL Certificate Issues:**
   ```bash
   # Reinitialize certificates
   ./scripts/init-letsencrypt.sh
   ```

2. **Database Connection Issues:**
   ```bash
   # Check database status
   docker-compose exec postgres pg_isready
   ```

3. **Permission Issues:**
   ```bash
   # Fix WordPress permissions
   docker-compose exec wordpress chown -R www-data:www-data /var/www/html
   ```

### Health Checks
All services include health checks. Check status with:
```bash
docker-compose ps
```

## Production Deployment

1. Set strong passwords in `.env`
2. Configure domain DNS
3. Run SSL initialization
4. Setup monitoring
5. Configure backup schedules
6. Test all functionality

## Docker Installation Script

The project includes an automated Docker installation script (`install-docker.sh`) that:

- **Removes old Docker packages** to avoid conflicts
- **Adds Docker's official GPG key** and repository
- **Installs Docker Engine** with all required components
- **Installs Docker Compose** (standalone version)
- **Configures permissions** for non-root users
- **Verifies installation** with test containers
- **Provides detailed logging** and error handling

### Script Features

- ✅ **Ubuntu version detection** and compatibility checks
- ✅ **Prerequisite installation** (ca-certificates, curl, gnupg)
- ✅ **GPG key verification** for security
- ✅ **Repository configuration** with proper architecture detection
- ✅ **Service management** (start, enable, verify)
- ✅ **Permission configuration** for non-root usage
- ✅ **Installation verification** with hello-world test
- ✅ **Comprehensive error handling** and logging
- ✅ **User-friendly output** with color-coded messages

### Usage

```bash
# Make executable and run
chmod +x install-docker.sh
./install-docker.sh

# Or run directly
bash install-docker.sh
```

The script will guide you through the installation process and provide post-installation instructions.

## Support

For issues and questions:
- Check logs: `docker-compose logs`
- Verify configuration: `docker-compose config`
- Test connectivity: `docker-compose exec wordpress wp --info`
- Docker installation issues: Check the script output and logs

## License

This project is licensed under the MIT License.
