#!/bin/bash

# FastKart Laravel API Deployment Script
# This script sets up the FastKart Laravel API on a production server

set -e

echo "🚀 Starting FastKart Laravel API deployment..."

# Configuration
PROJECT_PATH="/var/www/html/fastkart-laravel-api"
NGINX_CONF_PATH="/etc/nginx/sites-available/fastkart"
NGINX_ENABLED_PATH="/etc/nginx/sites-enabled/fastkart"

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

print_status "Setting up file permissions..."
# Set proper permissions
sudo chown -R www-data:www-data "$PROJECT_PATH"
sudo chmod -R 755 "$PROJECT_PATH"
sudo chmod -R 775 "$PROJECT_PATH/storage"
sudo chmod -R 775 "$PROJECT_PATH/bootstrap/cache"

print_status "Installing/updating Composer dependencies..."
# Install Composer dependencies
if [ ! -f "composer.phar" ]; then
    curl -sS https://getcomposer.org/installer | php
fi
php composer.phar install --optimize-autoloader --no-dev

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
sudo cp docker/nginx/production.conf "$NGINX_CONF_PATH"
sudo ln -sf "$NGINX_CONF_PATH" "$NGINX_ENABLED_PATH"

print_status "Testing Nginx configuration..."
sudo nginx -t

print_status "Reloading Nginx..."
sudo systemctl reload nginx

print_status "Setting up Docker containers..."
# Start Docker containers
if command -v docker-compose &> /dev/null; then
    docker-compose -f docker-compose.prod.yml up -d
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    docker compose -f docker-compose.prod.yml up -d
else
    print_error "Docker or Docker Compose not found!"
    print_warning "Please install Docker and Docker Compose to run the application"
fi

print_status "Setting up cron job for Laravel scheduler..."
# Add cron job for Laravel scheduler
(crontab -l 2>/dev/null; echo "* * * * * cd $PROJECT_PATH && php artisan schedule:run >> /dev/null 2>&1") | crontab -

print_status "Final permission check..."
# Final permission check
sudo chown -R www-data:www-data "$PROJECT_PATH"
sudo chmod -R 755 "$PROJECT_PATH"
sudo chmod -R 775 "$PROJECT_PATH/storage"
sudo chmod -R 775 "$PROJECT_PATH/bootstrap/cache"

echo ""
print_status "🎉 Deployment completed successfully!"
echo ""
print_warning "⚠️  Important next steps:"
echo "1. Update your .env file with production database credentials"
echo "2. Update your .env file with production mail settings"
echo "3. Update your .env file with production payment gateway credentials"
echo "4. Update the Nginx configuration with your actual domain name"
echo "5. Set up SSL certificates (Let's Encrypt recommended)"
echo "6. Configure your DNS to point to this server"
echo "7. Test all API endpoints"
echo ""
print_status "Your FastKart Laravel API should now be accessible!"