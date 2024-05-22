---
title: Introduction
---

# Introduction

In order to deploy our freshly built Docker image to Kubernetes, several options are available:

* **Manual deployment**: You can manually deploy your Docker image to Kubernetes using `kubectl` commands and YAML manifests
* **Helm chart**: You can use a [Helm](https://helm.sh/) chart to deploy your Docker image to Kubernetes
* **Kustomize**: You can use [Kustomize](https://kustomize.io/) to deploy your Docker image to Kubernetes
* **GitOps**: You can use GitOps ([ArgoCD](https://argo-cd.readthedocs.io/en/stable/), [Flux](https://fluxcd.io/)) to deploy your Docker image to Kubernetes

In this guide, we'll be using the **Helm chart** option to deploy our Docker image to Kubernetes, along with everything else required to run Magento / Adobe Commerce.
