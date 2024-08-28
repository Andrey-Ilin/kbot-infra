# KBOT Application Infrastructure

This README provides instructions for setting up and deploying the KBOT application using Terraform, Flux CD, and Kubernetes.

## Prerequisites

- Terraform installed
- Kubernetes cluster (to be created by Terraform)
- Flux CD (to be installed after cluster creation)
- `kubectl` CLI tool
- `sops` and `age` for secret management
- Helm (for chart deployment)

## KBOT Repository

The main KBOT application code is hosted at:

```
https://github.com/Andrey-Ilin/kbot
```

## Infrastructure Setup

### 1. Run Terraform to Create Infrastructure

Before setting up Flux and KBOT, you need to create the necessary infrastructure using Terraform:

1. Navigate to your Terraform configuration directory.
2. Initialize Terraform:
   ```bash
   terraform init
   ```
3. Review the planned changes:
   ```bash
   terraform plan
   ```
4. Apply the Terraform configuration to create the infrastructure:
   ```bash
   terraform apply
   ```
5. Confirm the action by typing `yes` when prompted.

After Terraform completes, it will output information about the created resources, including details about your new Kubernetes cluster.

### 2. Create Git Repository for Flux

Create a new Git repository named `flux-gitops` to manage your Flux configuration.

### 3. Set Up Cluster Resources

After the infrastructure is created and Flux is installed, follow these steps:

In your `flux-gitops` repository, create a folder structure `/clusters/demo` and add the following files:

`ns.yaml` - Define the demo namespace:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo
```

`kbot-gr.yaml` - GitRepository resource for KBOT:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: kbot
  namespace: demo
spec:
  interval: 1m0s
  ref:
    branch: main
  url: https://github.com/Andrey-Ilin/kbot
```

`kbot-helmrelease.yaml` - HelmRelease for KBOT deployment:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: kbot
  namespace: demo
spec:
  chart:
    spec:
      chart: ./helm
      reconcileStrategy: ChartVersion
      sourceRef:
        kind: GitRepository
        name: kbot
  interval: 1m0s
```

### 4. Secret Management

Install required tools:

```bash
brew install sops age
```

Generate Age key:

```bash
age-keygen -o age.agekey
```

Configure SOPS by creating a `.sops.yaml` file in your flux repository root:

```yaml
creation_rules:
  - path_regex: .*\.(yaml|yml)
    encrypted_regex: ^(data|stringData)$
    age: <your-age-public-key>
```

Create a file `kbot-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: kbot
  namespace: demo
type: Opaque
stringData:
  token: your-telegram-token-here
```

Encrypt the secret:

```bash
sops -e -i kbot-secret.yaml
```

Update HelmRelease by adding the following to your HelmRelease spec:

```yaml
values:
  env:
    - name: TELE_TOKEN
      valueFrom:
        secretKeyRef:
          name: kbot
          key: token
```

Create Flux Kustomization for Secret. In the `flux-system` folder, create `kbot-secret.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: kbot-secret
  namespace: flux-system
spec:
  interval: 1m0s
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./
  prune: true
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

Update Main Kustomization by adding the secret to your main Kustomization file:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- gotk-components.yaml
- gotk-sync.yaml
- kbot-secret.yaml
```

### 5. Finalize Setup

Commit all the changes to your `flux-gitops` repository.

Create Age Secret in Cluster. On your Kubernetes cluster, create a secret with the Age private key:

```bash
kubectl create secret generic sops-age \
  --namespace=flux-system \
  --from-file=age.agekey=./age.agekey
```

## Conclusion

With these steps completed, your infrastructure should be set up with Terraform, and Flux should be configured to deploy your KBOT application, manage its secrets, and keep it in sync with your Git repositories. Monitor your cluster to ensure everything is running as expected.

For troubleshooting or more information, refer to the Terraform documentation, Flux documentation, or the KBOT repository README.
