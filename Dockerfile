FROM php:8.3.7-fpm-bookworm AS php

ENV MAGE_MODE=production

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libfreetype6-dev libicu-dev libjpeg62-turbo-dev libpng-dev libxslt1-dev libzip-dev libwebp-dev

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) bcmath gd intl opcache pdo_mysql soap sockets xsl zip

# Composer épinglé et vérifié : SHA-256 recoupée entre getcomposer.org, la release GitHub et la signature GPG de Packagist.
ARG COMPOSER_VERSION=2.10.3
ARG COMPOSER_SHA256=7a2d379d5b8ffdaa028580ef26494c36d2feef4b178d3dd1473a4dbc5e17c8d6
RUN curl -fsSL -o /usr/local/bin/composer "https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar" \
    && echo "${COMPOSER_SHA256}  /usr/local/bin/composer" | sha256sum -c - \
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
