---
title: New Relic
layout: doc
---

# New Relic

As detailed in the [official New Relic documentation](https://docs.newrelic.com/docs/apm/agents/php-agent/installation/php-agent-installation-overview/), the PHP agent consists of two components:

* A PHP extension, which collects data from your application
* A local proxy daemon, which transmits the data to New Relic

In this section, we'll cover how to install the New Relic PHP extension, which will forward data to the New Relic daemon.

Installation of the New Relic daemon in your Kubernetes cluster will be covered in a separate section, under Deployment part.

## Installation

The PHP extension can be downloaded from https://download.newrelic.com/php_agent/release/. The latest version at the time of writing is `10.21.0.11`.

To install the New Relic PHP extension, follow these steps:

* Create a `newrelic.ini` file:

::: code-group

```ini [newrelic.ini]
extension = "newrelic.so"

[newrelic]
newrelic.license = "${NEWRELIC_LICENSE_KEY}"
newrelic.appname = "${NEWRELIC_APP_NAME}"
newrelic.daemon.address = "${NEWRELIC_DAEMON_HOST}:${NEWRELIC_DAEMON_PORT}"
newrelic.daemon.dont_launch = 3
```

:::

> [!NOTE]
> To make the configuration portable, we recommend using environment variables for the `NEWRELIC_LICENSE_KEY`, `NEWRELIC_APP_NAME`, `NEWRELIC_DAEMON_HOST`, and `NEWRELIC_DAEMON_PORT` values.
> Therefore, those values should be set as environment variables where the PHP process is running (discussed in the Deployment section).

* Download the PHP extension and copy the configuration file in your Docker image:

::: code-group

```dockerfile [Dockerfile]
FROM php:<tag>

# Install New Relic PHP extension
RUN curl -sSL https://download.newrelic.com/php_agent/release/newrelic-php5-10.21.0.11-linux.tar.gz -o /tmp/newrelic.tgz \
    && tar -xzf /tmp/newrelic.tgz -C /tmp \
    && cp newrelic-php5-10.21.0.11-linux/agent/aarch64/newrelic-20230831.so $(php -r 'echo ini_get("extension_dir");')/newrelic.so \
    && rm -rf /tmp/newrelic*

# Copy the New Relic configuration file
COPY newrelic.ini /usr/local/etc/php/conf.d/newrelic.ini
```

:::
