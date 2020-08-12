#!/bin/bash

# Exit on error
set -e

composer create-project --ignore-platform-reqs --repository-url=https://repo.magento.com/ magento/project-community-edition magento "2.3.*"
