---
title: Environment variables
layout: doc
---

# Environment variables

Following the [12-factor app](https://12factor.net/config) methodology, and especially the [Configuration](https://12factor.net/config) section, environment variables should be used to store environment-specific configuration, such as database credentials, API keys, and other configuration values that change between environments.

## `config.php` / `core_config_data`

Magento / Adobe Commerce [allows to override any system configuration using environment variables](https://experienceleague.adobe.com/en/docs/commerce-operations/configuration-guide/deployment/examples/example-environment-variables), following the patterns below.

The slash character of config paths should be replaced with double underscores:

| Config path             | Environment variable                                     | Scope                   |
|-------------------------|----------------------------------------------------------|-------------------------|
| `dev/js/merge_files`    | `CONFIG__DEFAULT__DEV__JS__MERGE_FILES`                  | `default`               |
| `web/unsecure/base_url` | `CONFIG__STORES__MYSTORECODE__WEB__UNSECURE__BASE_URL`   | `mystorecode` store     |
| `web/secure/base_url`   | `CONFIG__WEBSITES__MYWEBSITECODE__WEB__SECURE__BASE_URL` | `mywebsitecode` website |

> [!WARNING] 
> These environment values only take precedence over values in `config.php` and the database (`core_config_data`).

> [!NOTE]
> You need to use encrypted values for sensitive configuration (ie. payment gateway credentials) environment variables.

> [!IMPORTANT]
> Magento / Adobe Commerce caches the configuration values. If you change the value of an environment variable, you need to clear the cache to see the changes.

In a regular Magento / Adobe Commerce deployment, you might need to define the following environment variables for your config:

| Variable name                | Description                                                                 |
|------------------------------|-----------------------------------------------------------------------------|
| `MAGENTO_DATABASE_HOST`      | Database host                                                               |


## `env.php`

Magento / Adobe Commerce does not offer a mechanism similar to the one above for values of `env.php`.

Easy way to be able to define database connection info and such using environment variables, is taking advantage of PHP's `getenv()` function:

```php
<?php
    ...
    'db' => [
        'table_prefix' => '',
        'connection' => [
            'default' => [
                'host' => getenv('MAGENTO_DATABASE_HOST'),
                'dbname' => getenv('MAGENTO_DATABASE_NAME'),
                'username' => getenv('MAGENTO_DATABASE_USERNAME'),
                'password' => getenv('MAGENTO_DATABASE_PASSWORD'),
                'model' => 'mysql4',
                'engine' => 'innodb',
                'initStatements' => 'SET NAMES utf8;',
                'active' => '1'
            ]
        ]
    ],
    ...
```

You may also define defaults for those environment variables in your `env.php` file, using PHP's ternary operator `?:`:

```php
<?php
    ...
    'db' => [
        'connection' => [
            'default' => [
                'host' => getenv('MAGENTO_DATABASE_HOST') ?: 'localhost',
                'dbname' => getenv('MAGENTO_DATABASE_NAME') ?: 'magento',
                'username' => getenv('MAGENTO_DATABASE_USERNAME') ?: 'root',
                'password' => getenv('MAGENTO_DATABASE_PASSWORD') ?: 'root',
                ...
            ]
        ]
    ],
    ...
```
