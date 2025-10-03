# Use PHP 8.2 FPM as base image
FROM php:8.2-fpm

# Set working directory
WORKDIR /var/www/html/fastkart-laravel-api

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libicu-dev \
    libssl-dev \
    pkg-config \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    intl

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy composer files and install dependencies
    COPY composer.json ./
    RUN composer install --no-dev --optimize-autoloader --no-scripts --verbose --ignore-platform-reqs

# Copy application code
COPY . .

# Note: Skipping composer dump-autoload to avoid production issues
# The autoloader is already optimized during composer install --optimize-autoloader

# Create directories if they don't exist and set permissions
RUN mkdir -p /var/www/html/fastkart-laravel-api/storage/app/public \
    && mkdir -p /var/www/html/fastkart-laravel-api/storage/framework/cache \
    && mkdir -p /var/www/html/fastkart-laravel-api/storage/framework/sessions \
    && mkdir -p /var/www/html/fastkart-laravel-api/storage/framework/views \
    && mkdir -p /var/www/html/fastkart-laravel-api/storage/logs \
    && mkdir -p /var/www/html/fastkart-laravel-api/bootstrap/cache \
    && chown -R www-data:www-data /var/www/html/fastkart-laravel-api \
    && chmod -R 755 /var/www/html/fastkart-laravel-api \
    && chmod -R 775 /var/www/html/fastkart-laravel-api/storage \
    && chmod -R 775 /var/www/html/fastkart-laravel-api/bootstrap/cache

# Copy PHP configuration
COPY docker/php/php.ini /usr/local/etc/php/conf.d/custom.ini

# Create startup script
RUN echo '#!/bin/bash\n\
# Fix permissions on startup\n\
chown -R www-data:www-data /var/www/html/fastkart-laravel-api\n\
chmod -R 755 /var/www/html/fastkart-laravel-api\n\
chmod -R 775 /var/www/html/fastkart-laravel-api/storage\n\
chmod -R 775 /var/www/html/fastkart-laravel-api/bootstrap/cache\n\
# Start PHP-FPM\n\
exec php-fpm' > /usr/local/bin/start.sh && chmod +x /usr/local/bin/start.sh

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# Start PHP-FPM with permission fix
CMD ["/usr/local/bin/start.sh"]