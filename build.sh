#!/bin/bash

# Exit on error
set -e

docker build -t clickandmortar/magento-kubernetes-fpm:2.3 --target php -f Dockerfile .
docker build -t clickandmortar/magento-kubernetes-nginx:2.3 --target nginx -f Dockerfile .
