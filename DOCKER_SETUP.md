# FastKart API - Docker Setup Guide

This guide will help you set up the FastKart API using Docker containers for a consistent development environment.

## Prerequisites

- Docker Desktop for Windows
- Docker Compose (included with Docker Desktop)
- Git (for cloning the repository)

## Quick Start

1. **Clone the repository** (if not already done):
   ```bash
   git clone <your-repository-url>
   cd fastkart-api
   ```

2. **Copy the Docker environment file**:
   ```bash
   copy .env.docker .env
   ```

3. **Build and start the containers**:
   ```bash
   docker-compose up -d --build
   ```

4. **Install dependencies and set up the application**:
   ```bash
   docker-compose exec app composer install
   docker-compose exec app php artisan key:generate
   docker-compose exec app php artisan migrate
   docker-compose exec app php artisan db:seed
   ```

5. **Access the application**:
   - API: http://localhost:8000
   - phpMyAdmin: http://localhost:8080
   - Mailhog: http://localhost:8025

## Services Overview

### Main Services

- **app**: Laravel application (PHP 8.2 + Nginx)
- **mysql**: MySQL 8.0 database
- **redis**: Redis cache and session store
- **queue**: Laravel queue worker
- **scheduler**: Laravel task scheduler

### Development Services

- **phpmyadmin**: Database management interface
- **mailhog**: Email testing service

## Detailed Setup Instructions

### 1. Environment Configuration

The `.env.docker` file contains Docker-optimized settings:

- Database host: `mysql` (container name)
- Redis host: `redis` (container name)
- Mail host: `mailhog` (for testing emails)

### 2. Database Setup

The MySQL container will automatically create the database. To set up your tables:

```bash
# Run migrations
docker-compose exec app php artisan migrate

# Seed the database (optional)
docker-compose exec app php artisan db:seed
```

### 3. Storage Permissions

Ensure proper permissions for Laravel storage:

```bash
docker-compose exec app chown -R www-data:www-data /var/www/html/storage
docker-compose exec app chmod -R 755 /var/www/html/storage
```

## Common Commands

### Container Management

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Rebuild containers
docker-compose up -d --build

# View logs
docker-compose logs -f app

# Access app container shell
docker-compose exec app bash
```

### Laravel Commands

```bash
# Run Artisan commands
docker-compose exec app php artisan <command>

# Install Composer packages
docker-compose exec app composer install

# Run tests
docker-compose exec app php artisan test

# Clear caches
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:clear
docker-compose exec app php artisan view:clear
```

### Database Operations

```bash
# Access MySQL shell
docker-compose exec mysql mysql -u root -p fastkart

# Backup database
docker-compose exec mysql mysqldump -u root -p fastkart > backup.sql

# Restore database
docker-compose exec -T mysql mysql -u root -p fastkart < backup.sql
```

## File Structure

```
fastkart-api/
├── docker/
│   ├── nginx/
│   │   └── default.conf          # Nginx configuration
│   ├── php/
│   │   └── php.ini               # PHP configuration
│   ├── mysql/
│   │   └── my.cnf                # MySQL configuration
│   └── supervisor/
│       └── supervisord.conf      # Process manager configuration
├── Dockerfile                    # Main application container
├── docker-compose.yml           # Service orchestration
├── .dockerignore                # Docker build exclusions
├── .env.docker                  # Docker environment variables
└── DOCKER_SETUP.md             # This documentation
```

## Port Mappings

| Service | Internal Port | External Port | Description |
|---------|---------------|---------------|-------------|
| app | 80 | 8000 | Laravel application |
| mysql | 3306 | 3306 | MySQL database |
| redis | 6379 | 6379 | Redis cache |
| phpmyadmin | 80 | 8080 | Database admin |
| mailhog | 8025 | 8025 | Email testing UI |
| mailhog | 1025 | 1025 | SMTP server |

## Troubleshooting

### Common Issues

1. **Port conflicts**: If ports are already in use, modify the port mappings in `docker-compose.yml`

2. **Permission issues**: Run the storage permission commands mentioned above

3. **Database connection errors**: Ensure the MySQL container is fully started before running migrations

4. **Memory issues**: Increase Docker Desktop memory allocation in settings

### Useful Debug Commands

```bash
# Check container status
docker-compose ps

# View container logs
docker-compose logs <service-name>

# Inspect container
docker-compose exec <service-name> bash

# Check Docker resources
docker system df
```

## Production Considerations

For production deployment:

1. **Environment Variables**: Update `.env` with production values
2. **SSL/TLS**: Configure HTTPS with proper certificates
3. **Database**: Use managed database services
4. **Caching**: Configure Redis clustering if needed
5. **Monitoring**: Add logging and monitoring solutions
6. **Backups**: Implement automated backup strategies

## Performance Optimization

### Development

- Use volume mounts for faster file changes
- Enable OPcache for better PHP performance
- Use Redis for sessions and caching

### Production

- Use multi-stage builds to reduce image size
- Implement proper caching strategies
- Use CDN for static assets
- Configure horizontal scaling

## Security Notes

- Change default passwords in production
- Use secrets management for sensitive data
- Implement proper firewall rules
- Regular security updates for base images
- Enable SSL/TLS encryption

## Support

For issues related to:
- Docker setup: Check this documentation
- Laravel application: Refer to Laravel documentation
- FastKart specific features: Check the main README.md

---

**Note**: This Docker setup is optimized for development. For production deployment, additional security and performance configurations are recommended.