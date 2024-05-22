---
title: Docker
---

# Docker

In this section, we'll create a `Dockerfile` to build our Docker image and deploy it.

The instructions below will be using the [official PHP Docker image](https://hub.docker.com/_/php) as a base image.
You may need to adapt it to your needs, depending on your project requirements, such as PHP version, extensions, etc.

Since Magento 2.4.7 is compatible with PHP 8.3, we'll be using this version.

## Choice of base image

When choosing a PHP base image, we'd generally go with `8.3-fpm`, which seems to be the most popular choice.

However, you should consider the following:

* This image is based on Debian, which may not be the best choice for production, as it's not as lightweight as Alpine
* The underlying Debian version may be upgraded, which may break your build: `8.3-fpm` is available on `bookworm` (`8.3-fpm-bookworm`) and `bullseye` (`8.3-fpm-bullseye`)
* Although using a minor version of PHP is generally safe, you may want to use a specific version, such as `8.3.7-fpm` to avoid any surprises
* If you need to have reproducible builds, you may use the (short or full) `sha256` digest of the image, such as `php@sha256:606222f6366a` instead of `php:8.3.7-fpm-bookworm`

> [!TIP]
> A general rule of thumb is to use the most specific version of the base image, such as `8.3.7-fpm-bookworm`, to avoid any surprises, but still be able to benefit from security updates.

At this point, your `Dockerfile` should look like this:

```dockerfile
FROM php:8.3.7-fpm-bookworm
```

Let's also define `/app` as our base working directory, where we'll be copying our Magento / Adobe Commerce project files:

```dockerfile
WORKDIR /app
```

We'll also define the `MAGE_MODE` environment variable, which is required by Magento / Adobe Commerce to know we're building for production:

```dockerfile
ENV MAGE_MODE=production
```

## PHP extensions

Now that we have our base image, we need to install the necessary PHP extensions and their dependencies.

Required PHP extensions are listed in the [official system requirements](https://experienceleague.adobe.com/en/docs/commerce-operations/installation-guide/system-requirements#php-extensions), under `Commerce on-premises` tab.

> [!NOTE]
> This guide targets PHP 8.3, which already includes some of the required extensions.
> You may need to install additional extensions, run `docker run --rm php:<tag> php -m` to list the already installed extensions in the image you're planning to use.

For our PHP 8.3 base image, the missing extensions we need to install are:

* `bcmath`
* `gd`
* `intl`
* `pdo_mysql`
* `soap`
* `sockets`
* `xsl`
* `zip`

Although not listed explicitly, `opcache` and `pcntl` extensions are also required for optimal performance.

Let's add the necessary intrusctions in our `Dockerfile`:

```dockerfile
# Install required PHP extensions system dependencies
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libfreetype6-dev libicu-dev libjpeg62-turbo-dev libpng-dev libxslt1-dev libzip-dev libwebp-dev

# Configure PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp

# Install required PHP extensions
RUN docker-php-ext-install -j$(nproc) bcmath gd intl opcache pcntl pdo_mysql soap sockets xsl zip
```

## Composer

Next, we need to install [Composer](https://getcomposer.org/), which is a dependency manager for PHP.

> [!NOTE]
> Magento / Adobe Commerce 2.4.7 is compatible with Composer 2.7.
> Similar to PHP base image, you may want to use a specific version of Composer to avoid any surprises.
> However, in such case, you may need to update the `Dockerfile` when a new version of Composer is released.

To install Composer 2.x latest version, add the following instructions to your `Dockerfile`:

```dockerfile
RUN curl -sSL https://getcomposer.org/download/latest-2.x/composer.phar -o /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer
```

To benefit from Docker layer cache when rebuilding without change to `composer.json` or `composer.lock`, you may want to copy `composer.json` and `composer.lock` files separately, along with `auth.json` (required to authenticate against `repo.magento.com`):

```dockerfile
COPY composer.json composer.lock auth.json /app/
```

Then, run `composer install` to install the dependencies:

```dockerfile
RUN composer install \
    --no-interaction \
    --no-dev \
    --optimize-autoloader\
    --no-progress\
    --no-suggest
```

At this point, the `/app` directory in your Docker image looks like this:

```plaintext
.
|-- auth.json
|-- composer.json
|-- composer.lock
`-- vendor
    |-- 2tvenom
    |-- astock
    |-- autoload.php
    |-- aws
    |-- bacon
    |-- bin
    |-- braintree
    |-- brick
    |-- christian-riesen
    |-- colinmollenhour
    |-- composer
    |-- dasprid
    |-- elasticsearch
    |-- endroid
    |-- ezimuel
    |-- ezyang
    |-- firebase
    |-- google
    |-- guzzlehttp
    |-- justinrainbow
    |-- laminas
    |-- league
    |-- magento
    |-- monolog
    |-- ... (and many more)
    |-- webmozart
    |-- webonyx
    `-- wikimedia
```

The `auth.json` file can be safely removed from the image after running `composer install`:

```dockerfile
RUN rm -f auth.json
```

## Magento / Adobe Commerce

Now that we have Composer installed and our dependencies ready, we can copy our Magento / Adobe Commerce project files to the image.

```dockerfile
COPY . /app/
```

You may want to add a `.dockerignore` file to exclude unnecessary files and directories from being copied to the image.

For example, you may want to exclude `node_modules`, `vendor`, `.git`, etc.

The following directories are generally excluded:

```
pub/media
pub/static
var
```

> [!NOTE]
> As the image should be built from a raw clone of the repository, you may not need to exclude anything.

### DI compilation

The `setup:di:compile` command generates the `generated` directory, which contains generated code and classes.

To avoid running into memory issues, you may want to increase the memory limit for the PHP process:

```dockerfile
RUN php -d memory_limit=2G bin/magento setup:di:compile
```

### Static content

This part is one of the trickiest, as it generates static content for all locales and themes, and needs to be aware of the websites structure.

Therefore, you should dump the necessary database configuration into `app/etc/config.php`:

```shell
bin/magento app:config:dump scopes themes i18n
```

> [!IMPORTANT]
> This command should be run outside of the Docker image, as it requires a database connection.
> The resulting `config.php` should be added to the VCS, so it's available when building the Docker image.

> [!NOTE]
> This command will need to be run every time you change the configuration, such as changing the websites structure, adding new themes, etc.

Additionally, the `app/etc/env.php` needs to be moved temporarily during the static content deployment, to avoid database lookup issues:

```dockerfile
RUN mv app/etc/env.php app/etc/env.php.bak
```

Then, you can run the `setup:static-content:deploy` command:

```dockerfile
RUN php -d memory_limit=2G bin/magento setup:static-content:deploy \
    --max-execution-time=3600 \
    --jobs=$(nproc)
```

To make this process more efficient, you may want to run the `setup:static-content:deploy` command for a specific locale and theme only.
The following options are available:

* `--area` (repeatable): `frontend` or `adminhtml`, defaults to `all`
* `--theme` (repeatable): themes to build, i.e. `Magento/luma`, `Magento/backend`, defaults to `all`
* `--language` (repeatable): locales to build, i.e. `en_US`, `de_DE`, defaults to `all`

> [!IMPORTANT]
> Note that even in headless setups, the `frontend` area is required, notably to generate emails and PDFs.

Once the static content is deployed, we can move back the `env.php` file:

```dockerfile
RUN mv app/etc/env.php.bak app/etc/env.php
```

## PHP configuration

Although the PHP configuration is generally good enough for most cases, you may want to tweak it to your needs.

Here is an example of additional PHP configuration you may define:

::: code-group

<<< @/docker/php/custom.ini{ini}

:::

> [!TIP]
> PHP is able to read environment variables, so you may want to define some of the configuration options as environment variables, such as `memory_limit`, etc.
> Syntax is `memory_limit = ${PHP_MEMORY_LIMIT}`, which can be useful to have a different memory limit between CLI and FPM Pods.

The content of the above ini file should be saved in a file, such as `custom.ini`, along yout `Dockerfile`, and copied to the image:

```dockerfile
COPY custom.ini /usr/local/etc/php/conf.d/custom.ini
```

## FPM configuration

Here is a recommended pool configuration:

::: code-group

<<< @/docker/php/www.conf{ini}

:::

The content of the above file should be saved in a file, such as `www.conf`, along yout `Dockerfile`, and copied to the image:

```dockerfile
COPY www.conf /usr/local/etc/php-fpm.d/www.conf
```

> [!IMPORTANT]
> As you may have noticed, we're using `pm = static` instead of `pm = dynamic`.<br/>
> When working in a Kubernetes environment, we need to have control about how much resources our pods are using.
> Using `pm = static` allows us to set a fixed number of workers, which is easier to manage in a Kubernetes environment.<br/>
> We'll dig deeper into this in the Kubernetes resources allocation section.

## nginx

Now that we have our PHP-FPM image ready, we need to add an nginx server to serve our Magento / Adobe Commerce project, communicating with PHP-FPM using fastcgi.

To serve static assets in an efficient way, we'll also copy the `pub/static` directory to the nginx image.

> [!INFO]
> The same way we did for the PHP image, we'll be using the [official nginx image](https://hub.docker.com/_/nginx) as a base image.<br/>
> We recommend using the `alpine` version, which is lightweight and secure.<br/>
> As with PHP image, you may want to use a specific version of the image to avoid any surprises.<br/>
> Note that Adobe recommends using version 1.24 of nginx for Magento 2.4.7.

A sample `nginx.conf.sample` file is provided in the Magento / Adobe Commerce repository, which you can use as a base for your configuration.

Create a `vhost.conf` file:

```nginx
upstream fastcgi_backend {
   server  127.0.0.1:9000;
}

server {
   listen 80;
   server_name <your-magento-hostname>;
   set $MAGE_ROOT /app;
   set $MAGE_DEBUG_SHOW_ARGS 0;

   # Include the content of `nginx.conf.sample` here
}
```

Additionnaly, you may change the following in the resulting `vhost.conf` file:

* Uncomment the `# expires max;` line to enable caching of static assets, in `location /static/` block
* Change the access log format to JSON, to be able to parse it easily in a log aggregator, such as ELK stack, CloudWatch, etc.:

::: code-group

```nginx [At root level of vhost.conf]
log_format nginxlog_json escape=json 
    '{ "timestamp": "$time_iso8601", '
    '"remote_addr": "$remote_addr", '
    '"body_bytes_sent": $body_bytes_sent, '
    '"request_time": $request_time, '
    '"response_status": $status, '
    '"request": "$request", '
    '"request_method": "$request_method", '
    '"host": "$host",'
    '"remote_user": "$remote_user",'
    '"request_uri": "$request_uri",'
    '"query_string": "$query_string",'
    '"upstream_addr": "$upstream_addr",'
    '"http_x_forwarded_for": "$http_x_forwarded_for",'
    '"http_x_real_ip": "$http_x_real_ip",'
    '"http_referrer": "$http_referer", '
    '"http_user_agent": "$http_user_agent", '
    '"http_version": "$server_protocol" }';
```

```nginx [Within the server block]
access_log /dev/stdout nginxlog_json;
```

:::

The resulting `Dockefile` should look like this:

```dockerfile
FROM nginx:alpine

WORKDIR /app

COPY vhost.conf /etc/nginx/conf.d/default.conf
```

But hey, we don't have the `pub/static` directory yet! Let's discuss this in the next section.

## Multi-stage build

A Docker multi-stage build is a method that allows for the creation of smaller, more efficient container images by using multiple intermediate stages in a single `Dockerfile`, thereby isolating and discarding unnecessary build artifacts.

It also allows copying files from one stage to another, which is useful in our case, as we need to copy the `pub/static` directory from the PHP image to the nginx image.

Our `Dockerfile` will eventually look like this:

```dockerfile
# PHP-FPM image
FROM php:8.3.7-fpm-bookworm AS php

...

# Nginx image
FROM nginx:alpine

...

COPY --from=php /app/pub/static /app/pub/static
```

## Wrapping up

At this point, you should have a working `Dockerfile` that builds a Docker image containing your Magento / Adobe Commerce project files, ready to be deployed.

To build the resulting PHP-FPM and nginx images, run the following commands:

```shell
docker build --target php -t my-namespace/magento-php:<tag> .
docker build --target nginx -t my-namespace/magento-nginx:<tag> .
```

Then push the images to your container registry, using `docker push`.

> [!TIP]
> When cross-building images for different architectures, you may want to use the `--platform` flag to specify the target architecture, such as `linux/amd64`, `linux/arm64`, etc.

The complete `Dockerfile` can be found [here](https://github.com/ClickAndMortar/magento-kubernetes/blob/main/Dockerfile).

## Tagging strategy

It's a good practice to **tag your images with the Git commit (short) hash**, to be able to trace back the image to the code it was built from.

To make sure your deployments are consistent between environments, you should **use the same image for all environments**, and use environment variables to configure the image.

As Docker images can have multiple tags, here are some additional tags you may want to use:

* `latest`: the latest version of the image
* `<tag>`: the Git tag the image was built from
* `<branch>`: the Git branch the image was built from
