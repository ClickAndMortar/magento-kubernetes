---
title: Helm chart
---

# Helm chart

A [Helm](https://helm.sh/) chart is a collection of files that describe a set of Kubernetes resources. It allows you to define, install, and upgrade even the most complex Kubernetes applications.

## Deployment process

When deploying our Magento / Adobe Commerce, the process is as follows:

1. Run the `bin/magento setup:upgrade` command to update the database schema according to the new code and configuration
2. Update all the resources in the Kubernetes cluster with the new version of the application:
   * `Deployment`
   * `Service`
   * `Ingress`
   * `ConfigMap`
   * `Secret`
   * `CronJob`
   * Etc.
3. Wait for the new `Pods` to be ready
4. Flush the cache

> [!NOTE]
> When [using per release Redis ID prefixes](/guide/preparation/configuration#redis-id-prefix), there is no need to flush the cache after each deployment.

> [!IMPORTANT]
> We will rely on [Helm hooks](https://helm.sh/docs/topics/charts_hooks/) to run the `bin/magento setup:upgrade` in a Kubernetes `Job` (during the `pre-install` and `pre-upgrade` hooks).<br/>
> However, as the updated `ConfigMap` and `Secret` are not updated during the `Job` execution, you may need to declare environment variables directly on the hook `Job` on change, for instance if you change the MySQL password.

## Helm chart structure

Our Helm chart will be structured as follows:

```plaintext
chart/
├── templates
│   ├── _helpers.tpl
│   ├── configmap.yaml
│   ├── cronjob.yaml
│   ├── deployment.yaml
│   ├── hpa.yaml # HorizontalPodAutoscaler
│   ├── ingress.yml
│   ├── pdb.yml # PodDisruptionBudget
│   ├── secret.yaml
│   └── service.yaml
├── Chart.yaml
├── secrets.yaml
└── values.yaml
```

> [!NOTE]
> Our sample Magento / Adobe Commerce Helm Chart will soon be available in our [GitHub repository](https://github.com/ClickAndMortar/magento-kubernetes).

To follow Helm's best practices, you should initialize your Helm chart with the following command:

```shell
helm create mychart
```
