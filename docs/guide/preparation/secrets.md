---
title: Secrets
---

# Secrets

When working with Magento / Adobe Commerce, you'll need to store sensitive information, such as database credentials, API keys, etc.

There are many ways to manage secrets in a project:

* Stored encrypted in the codebase, using a tool like [sops](https://github.com/getsops/sops)
* Stored in a secret management system, like [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/), [Google Secret Manager](https://cloud.google.com/secret-manager), [Azure Key Vault](https://azure.microsoft.com/en-us/services/key-vault/), etc.
* Stored as CI variables in your CI/CD tool (GitHub Actions, GitLab CI, etc.) and injected at deploy time

Those sensitive values will eventually be injected as environment variables in your `Pods`, using Kubernetes `Secrets`.

The way you manage secrets in your project depends on your security requirements, team's workflow, and the tools you're using.

In this guide, we'll cover the usage of `sops` to encrypt secrets in your codebase, and how to use those encrypted secrets in your Kubernetes manifests.

## sops

`sops` is a tool that makes it easy to store, share, and manage secrets in your codebase.

It encrypts your secrets, stored in a YAML file, using a KMS key (AWS, GCP, etc.), an `age` key, or a GPG key.

You can then commit the encrypted file to your codebase, and decrypt it at deploy time. In our case, decrypting the file will be handled by [Helm secrets plugin](https://github.com/jkroepke/helm-secrets).

What's great about `sops` is that only the values are encrypted, not the structure of the file. This means that you can still version control the file, and see the changes made to it.

For example, this is what the update of the MySQL password in a `sops`-encrypted file using AWS KMS looks like:

::: code-group

```yaml [secrets.yaml]
mysql:
    password: ENC[AES256_GCM,data:xxxx,iv:xxxx,tag:xxxx,type:str] # [!code --]
    password: ENC[AES256_GCM,data:yyyy,iv:yyyy,tag:yyyy,type:str] # [!code ++]
stripe:
    secret_key: ENC[AES256_GCM,data:zzzz,iv:zzzz,tag:zzzz,type:str]
sops:
  kms:
    - arn: arn:aws:kms:eu-central-1:xxxxx:key/xxx-xxx-xxx
      created_at: "2024-01-01T00:00:00Z"
      enc: xxxx
      aws_profile: ""
  gcp_kms: []
  azure_kv: []
  hc_vault: []
  age: []
  lastmodified: "2024-01-02T01:02:03Z" # [!code --]
  lastmodified: "2024-01-03T01:02:03Z" # [!code ++]
  mac: ENC[AES256_GCM,data:xxxx,iv:xxxx,tag:xxxx,type:str] # [!code --]
  mac: ENC[AES256_GCM,data:yyyy,iv:yyyy,tag:yyyy,type:str] # [!code ++]
  pgp: []
  unencrypted_suffix: _unencrypted
  version: 3.7.3
```

:::

You may refer to the [official documentation](https://github.com/getsops/sops) to install `sops` and learn more about its usage.

We'll cover the usage of `sops` when deploying to Kubernetes using Helm, in the deployment section.
