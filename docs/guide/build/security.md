---
title: Security
---

# Security

## Running containers as an unprivileged user

Although our nginx and PHP FPM workers are running as unprivileged users (respectively `nginx` and `www-data`), our containers are still running as `root`.

This is a security risk, as an attacker who gains access to the container could escalate their privileges to `root` and potentially compromise the host system.

To mitigate this risk, we need to run our containers as an unprivileged user.

To run our containers as an unprivileged user, we need to create a new user and group in our `Dockerfile`, and then switch to that user before running our application.

Let's start by creating a new user, `docker`, and group in our `Dockerfile`, in both the PHP FPM and nginx stages:

```dockerfile
# Create a new group and user
RUN groupadd docker \
    && useradd -m -g docker docker

# Switch to the new user
USER docker
```

> [!NOTE]
> Switching to the new user in the `Dockerfile` is not mandatory, as it could be achieved by setting the `securityContext.runAsUser` property in the Kubernetes `Deployment` manifest.

We'll also need to make a change to our nginx configuration, as the unprivileged user `docker` does not have permission to bind to port `80`:

::: code-group
```nginx [vhost.conf]
server {
    listen 80; # [!code --]
    listen 8080; # [!code ++]
    ...
}
```
:::

## Scanning for vulnerabilities

We need to make sure that our image does not contain any known vulnerabilities, by scanning it with a vulnerability scanner.

There are many tools available to scan Docker images for vulnerabilities, exposed secrets and misconfigurations, such as [Trivy](https://aquasecurity.github.io/trivy/).

Trivy also scans for vulnerabilities in your Composer dependencies, which is very useful in our case.

You can run Trivy in your CI/CD pipeline to ensure that your images are free of vulnerabilities before deploying them to production.

## Advanced security features

We will cover advanced security features in dedicated section, such as:

* Read-only file system
* Hardening image
