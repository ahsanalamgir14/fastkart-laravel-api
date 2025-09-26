# FastKart Laravel API - Server Setup Guide

This guide will help you deploy the FastKart Laravel API on your production server at `/var/www/html/fastkart-laravel-api`.

## Prerequisites

Before starting, ensure your server has:

- Ubuntu 20.04+ or CentOS 8+ (recommended)
- Docker and Docker Compose installed
- Nginx installed
- MySQL 8.0+ (or use Docker MySQL)
- Redis (or use Docker Redis)
- PHP 8.1+ with required extensions
- Composer
- Git
- SSL certificate (Let's Encrypt recommended)

## Step 1: Server Preparation

### Install Required Software

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Nginx
sudo apt install nginx -y

# Install PHP and extensions
sudo apt install php8.1-fpm php8.1-mysql php8.1-redis php8.1-xml php8.1-gd php8.1-curl php8.1-mbstring php8.1-zip php8.1-bcmath -y

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
```

## Step 2: Upload Project Files

Upload your FastKart Laravel API project to `/var/www/html/fastkart-laravel-api`:

```bash
# Create directory
sudo mkdir -p /var/www/html/fastkart-laravel-api

# Set ownership (replace 'username' with your actual username)
sudo chown -R username:username /var/www/html/fastkart-laravel-api

# Upload files using SCP, SFTP, or Git
# Example with Git:
cd /var/www/html
git clone your-repository-url fastkart-laravel-api
```

## Step 3: Run Deployment Script

Make the deployment script executable and run it:

```bash
cd /var/www/html/fastkart-laravel-api
chmod +x deploy.sh
./deploy.sh
```

## Step 4: Configure Environment Variables

Edit the `.env` file with your production settings:

```bash
nano .env
```

### Important Settings to Update:

```env
# Application
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com

# Database
DB_HOST=mysql  # or your external MySQL host
DB_DATABASE=fastkart
DB_USERNAME=your_db_user
DB_PASSWORD=your_secure_password

# Mail
MAIL_HOST=your-smtp-host.com
MAIL_USERNAME=your-email@domain.com
MAIL_PASSWORD=your-email-password

# Payment Gateways (use live credentials)
STRIPE_KEY=pk_live_...
STRIPE_SECRET=sk_live_...
PAYPAL_MODE=live
PAYPAL_LIVE_CLIENT_ID=...
```

## Step 5: Configure Nginx

Update the Nginx configuration with your domain:

```bash
sudo nano /etc/nginx/sites-available/fastkart
```

Replace `your-domain.com` with your actual domain name in the configuration file.

## Step 6: SSL Certificate Setup

### Using Let's Encrypt (Recommended):

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Test auto-renewal
sudo certbot renew --dry-run
```

## Step 7: Start Services

```bash
# Start Docker containers
cd /var/www/html/fastkart-laravel-api
docker-compose -f docker-compose.prod.yml up -d

# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Check status
docker-compose -f docker-compose.prod.yml ps
sudo systemctl status nginx
```

## Step 8: Database Setup

If using external MySQL (not Docker):

```bash
# Create database and user
mysql -u root -p
CREATE DATABASE fastkart;
CREATE USER 'fastkart'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON fastkart.* TO 'fastkart'@'localhost';
FLUSH PRIVILEGES;
EXIT;

# Run migrations
cd /var/www/html/fastkart-laravel-api
php artisan migrate --force
php artisan db:seed --force
```

## Step 9: Configure Firewall

```bash
# Allow HTTP and HTTPS
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 22  # SSH
sudo ufw enable
```

## Step 10: Set Up Monitoring and Logs

```bash
# Create log rotation for Laravel logs
sudo nano /etc/logrotate.d/laravel

# Add this content:
/var/www/html/fastkart-laravel-api/storage/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
}
```

## Step 11: Performance Optimization

```bash
cd /var/www/html/fastkart-laravel-api

# Optimize Composer autoloader
composer install --optimize-autoloader --no-dev

# Cache configurations
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Enable OPcache (edit PHP configuration)
sudo nano /etc/php/8.1/fpm/php.ini

# Add/update these settings:
opcache.enable=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=2
opcache.fast_shutdown=1
```

## Step 12: Testing

Test your API endpoints:

```bash
# Test basic connectivity
curl -I https://your-domain.com

# Test API endpoint
curl -X GET https://your-domain.com/api/health

# Check Docker containers
docker-compose -f docker-compose.prod.yml logs
```

## Troubleshooting

### Common Issues:

1. **Permission Errors:**
   ```bash
   sudo chown -R www-data:www-data /var/www/html/fastkart-laravel-api
   sudo chmod -R 755 /var/www/html/fastkart-laravel-api
   sudo chmod -R 775 /var/www/html/fastkart-laravel-api/storage
   sudo chmod -R 775 /var/www/html/fastkart-laravel-api/bootstrap/cache
   ```

2. **Database Connection Issues:**
   - Check `.env` database credentials
   - Ensure MySQL service is running
   - Check firewall settings

3. **Nginx Configuration Issues:**
   ```bash
   sudo nginx -t  # Test configuration
   sudo systemctl reload nginx
   ```

4. **Docker Issues:**
   ```bash
   docker-compose -f docker-compose.prod.yml down
   docker-compose -f docker-compose.prod.yml up -d
   ```

## Maintenance

### Regular Tasks:

```bash
# Update dependencies
composer update

# Clear caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Backup database
mysqldump -u fastkart -p fastkart > backup_$(date +%Y%m%d).sql

# Monitor logs
tail -f storage/logs/laravel.log
tail -f /var/log/nginx/fastkart_error.log
```

## Security Checklist

- [ ] SSL certificate installed and working
- [ ] Firewall configured properly
- [ ] Database credentials are secure
- [ ] `.env` file permissions are restrictive (600)
- [ ] Regular security updates applied
- [ ] Backup strategy implemented
- [ ] Monitoring and alerting set up

## Support

If you encounter issues:

1. Check the Laravel logs: `storage/logs/laravel.log`
2. Check Nginx logs: `/var/log/nginx/fastkart_error.log`
3. Check Docker logs: `docker-compose -f docker-compose.prod.yml logs`
4. Verify all environment variables are set correctly

Your FastKart Laravel API should now be running successfully on your production server!