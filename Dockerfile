FROM php:8.3.7-fpm-bookworm AS php

ENV MAGE_MODE=production

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libfreetype6-dev libicu-dev libjpeg62-turbo-dev libpng-dev libxslt1-dev libzip-dev libwebp-dev

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) bcmath gd intl pdo_mysql soap sockets xsl zip

RUN curl -sSL https://getcomposer.org/download/latest-2.x/composer.phar -o /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer

WORKDIR /app

# The 2 steps below allow benefiting from Docker layer cache when rebuilding without change to composer.json
ADD composer.* auth.json /app/
RUN composer install --no-interaction --no-dev --optimize-autoloader --no-progress --no-suggest

COPY . /app/

RUN php -d memory_limit=2G bin/magento setup:di:compile

RUN mv app/etc/env.php app/etc/env.php.bak

RUN php -d memory_limit=2G bin/magento setup:static-content:deploy \
    --max-execution-time=3600 \
    --jobs=$(nproc)

RUN mv app/etc/env.php.bak app/etc/env.php

RUN rm -rf var/*

COPY docs/docker/php/custom.ini /usr/local/etc/php/conf.d/custom.ini
COPY docs/docker/php/www.conf /usr/local/etc/php-fpm.d/www.conf

FROM nginx as nginx

COPY docs/docker/nginx/vhost.nginx /etc/nginx/conf.d/default.conf

COPY --from=php /app/pub/static /app/pub/static
