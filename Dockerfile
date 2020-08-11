FROM php:7.2-fpm-buster as php

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y libfreetype6-dev libicu-dev net-tools libjpeg62-turbo-dev libmcrypt-dev libpng-dev libxslt1-dev libsodium-dev unzip wget

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install -j$(nproc) dom gd intl mbstring pdo_mysql xsl zip soap bcmath opcache pcntl \
  && pecl install apcu \
  && docker-php-ext-enable apcu \
  && pecl install -f libsodium

# Imagick
RUN apt-get -y install libmagickwand-dev --no-install-recommends \
    && pecl install imagick \
    && docker-php-ext-enable imagick

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /composer

RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && composer global require hirak/prestissimo

WORKDIR /app

COPY magento/composer.* auth.json /app/

RUN composer install --no-interaction --no-dev -o --no-progress --no-suggest --apcu-autoloader

RUN rm -f auth.json

COPY magento/ /app

ENV MAGE_MODE=production

RUN rm -f app/etc/env.php \
    && php -d memory_limit=1024M bin/magento setup:di:compile \
    && chown -R www-data:www-data /app/var /app/generated \
    && mv app/etc/config.php app/etc/config.php.orig \
    && mv app/etc/config.kube.php app/etc/config.php \
    # You might specify themes to build using -t flag and add locales to build at the end (ie. en_US en_GB)
    && php -d memory_limit=1024M bin/magento setup:static-content:deploy --jobs=$(nproc) --max-execution-time=3600 \
    && mv app/etc/config.php.orig app/etc/config.php \
    && mv app/etc/env.kube.php app/etc/env.php \
    && chown -R www-data var

FROM nginx as nginx

COPY nginx-vhost.conf /etc/nginx/conf.d/default.conf

COPY --from=php /app/pub /app/pub
