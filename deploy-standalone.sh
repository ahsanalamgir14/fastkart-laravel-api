#!/bin/bash

# FastKart Laravel API - Standalone Deployment Script (No Docker)
# This script sets up the FastKart Laravel API on a server without Docker

set -e

echo "🚀 Starting FastKart Laravel API standalone deployment..."

# Configuration
PROJECT_PATH="/var/www/html/fastkart-laravel-api"
NGINX_CONF_PATH="/etc/nginx/sites-available/fastkart"
NGINX_ENABLED_PATH="/etc/nginx/sites-enabled/fastkart"
PHP_VERSION="8.1"  # Adjust as needed

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for security reasons"
   exit 1
fi

# Check if project directory exists
if [ ! -d "$PROJECT_PATH" ]; then
    print_error "Project directory $PROJECT_PATH does not exist!"
    print_status "Please ensure your project is uploaded to $PROJECT_PATH"
    exit 1
fi

cd "$PROJECT_PATH"

print_status "Installing system dependencies..."
# Install required packages
sudo apt update
sudo apt install -y nginx mysql-server redis-server php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-mysql php${PHP_VERSION}-redis php${PHP_VERSION}-xml \
    php${PHP_VERSION}-gd php${PHP_VERSION}-curl php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-zip php${PHP_VERSION}-bcmath php${PHP_VERSION}-intl \
    php${PHP_VERSION}-soap php${PHP_VERSION}-imagick unzip curl

print_status "Setting up file permissions..."
# Set proper permissions
sudo chown -R www-data:www-data "$PROJECT_PATH"
sudo chmod -R 755 "$PROJECT_PATH"
sudo chmod -R 775 "$PROJECT_PATH/storage"
sudo chmod -R 775 "$PROJECT_PATH/bootstrap/cache"

print_status "Installing/updating Composer dependencies..."
# Install Composer if not exists
if ! command -v composer &> /dev/null; then
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
fi

# Install dependencies
composer install --optimize-autoloader --no-dev

print_status "Setting up environment file..."
# Copy production environment file
if [ ! -f ".env" ]; then
    cp .env.production .env
    print_warning "Please update .env file with your production settings!"
else
    print_warning ".env file already exists. Please verify it has production settings."
fi

print_status "Generating application key..."
# Generate application key if not set
php artisan key:generate --force

print_status "Setting up MySQL database..."
# Setup MySQL database
print_warning "Setting up MySQL database. You'll need to enter MySQL root password."
mysql -u root -p << EOF
CREATE DATABASE IF NOT EXISTS fastkart;
CREATE USER IF NOT EXISTS 'fastkart'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON fastkart.* TO 'fastkart'@'localhost';
FLUSH PRIVILEGES;
EOF

print_status "Updating .env with database credentials..."
# Update .env with database settings
sed -i 's/DB_HOST=mysql/DB_HOST=localhost/' .env
sed -i 's/DB_PASSWORD=secret/DB_PASSWORD=your_secure_password/' .env

print_status "Clearing and caching configuration..."
# Clear and cache config
php artisan config:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

print_status "Running database migrations..."
# Run migrations
php artisan migrate --force

print_status "Seeding database..."
# Seed database
php artisan db:seed --force

print_status "Creating symbolic link for storage..."
# Create storage link
php artisan storage:link

print_status "Setting up Nginx configuration..."
# Setup Nginx configuration
sudo cp nginx-standalone.conf "$NGINX_CONF_PATH"
sudo ln -sf "$NGINX_CONF_PATH" "$NGINX_ENABLED_PATH"

# Remove default Nginx site
sudo rm -f /etc/nginx/sites-enabled/default

print_status "Testing Nginx configuration..."
sudo nginx -t

print_status "Starting services..."
# Start and enable services
sudo systemctl enable nginx
sudo systemctl enable mysql
sudo systemctl enable redis-server
sudo systemctl enable php${PHP_VERSION}-fpm

sudo systemctl start mysql
sudo systemctl start redis-server
sudo systemctl start php${PHP_VERSION}-fpm
sudo systemctl reload nginx

print_status "Setting up cron job for Laravel scheduler..."
# Add cron job for Laravel scheduler
(crontab -l 2>/dev/null; echo "* * * * * cd $PROJECT_PATH && php artisan schedule:run >> /dev/null 2>&1") | crontab -

print_status "Setting up log rotation..."
# Setup log rotation
sudo tee /etc/logrotate.d/laravel > /dev/null << EOF
$PROJECT_PATH/storage/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
}
EOF

print_status "Final permission check..."
# Final permission check
sudo chown -R www-data:www-data "$PROJECT_PATH"
sudo chmod -R 755 "$PROJECT_PATH"
sudo chmod -R 775 "$PROJECT_PATH/storage"
sudo chmod -R 775 "$PROJECT_PATH/bootstrap/cache"

print_status "Setting up firewall..."
# Configure UFW firewall
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw --force enable

echo ""
print_status "🎉 Standalone deployment completed successfully!"
echo ""
print_warning "⚠️  Important next steps:"
echo "1. Update your .env file with production database password (currently set to 'your_secure_password')"
echo "2. Update your .env file with production mail settings"
echo "3. Update your .env file with production payment gateway credentials"
echo "4. Update the Nginx configuration with your actual domain name:"
echo "   sudo nano $NGINX_CONF_PATH"
echo "5. Set up SSL certificates:"
echo "   sudo apt install certbot python3-certbot-nginx"
echo "   sudo certbot --nginx -d your-domain.com"
echo "6. Configure your DNS to point to this server"
echo "7. Test all API endpoints"
echo ""
print_status "Your FastKart Laravel API should now be accessible!"
print_status "Test with: curl -I http://your-server-ip"