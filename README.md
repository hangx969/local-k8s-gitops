# local-k8s-gitops

A GitOps-based Kubernetes automated deployment platform using ArgoCD, Helm, and Kustomize.

## Repository Structure

```
local-k8s-gitops/
├── argocd/                        # ArgoCD configuration
│   ├── deploy.sh                  # One-click deployment script
│   ├── projects/
│   │   └── default-project.yaml   # AppProject definition
│   └── applicationsets/
│       ├── appset-helm.yaml       # Helm ApplicationSet
│       └── appset-kustomize.yaml  # Kustomize ApplicationSet
│
├── helm-charts/                   # Helm chart applications
│   ├── cert-manager/              # TLS certificate management
│   ├── ingress-nginx/             # Ingress controller
│   ├── istio-base/                # Istio base CRDs
│   ├── istiod/                    # Istio control plane
│   ├── istio-gateway/             # Istio ingress gateway
│   ├── jenkins/                   # CI/CD platform
│   └── nfs-provisioner/           # NFS dynamic storage provisioner
│
├── apps/                          # Kustomize applications
│   ├── base/                      # Base configs (environment-agnostic)
│   │   ├── bookinfo/              # Istio sample app
│   │   ├── istio-addons/          # Grafana, Jaeger, Kiali, Prometheus
│   │   └── argocd-istio/          # ArgoCD Istio gateway integration
│   └── overlays/                  # Environment-specific overrides
│       ├── bookinfo/
│       ├── istio-addons/
│       └── argocd-istio/
│
└── README.md
```

## Prerequisites

Before running the deployment, the following items must be prepared on the target cluster.

### 1. ArgoCD Installed

ArgoCD must be installed in the `argocd` namespace. The deploy script will verify this before proceeding.

### 2. NFS Server

The NFS provisioner (used by Jenkins for persistent storage) requires an NFS server.

**Install and start NFS on the server node:**

```bash
yum install nfs-utils -y
systemctl start rpcbind && systemctl enable rpcbind
systemctl start nfs-server && systemctl enable nfs-server
```

**Create the shared directory:**

```bash
mkdir /data/nfs_pro -p
echo "/data/nfs_pro *(rw,no_root_squash)" >> /etc/exports
exportfs -arv
```

**Verify the NFS server IP** matches the value in `helm-charts/nfs-provisioner/charts/values.dev.yaml`:

```yaml
nfs:
  server: 172.16.35.120      # <-- Change this to your NFS server IP
  path: /data/nfs_pro/
```

### 3. Port Availability

Ensure the following ports are **not occupied** on cluster nodes:

| Component | Ports | Reason |
|-----------|-------|--------|
| ingress-nginx | `80`, `443` | Runs as DaemonSet with `hostNetwork: true` |
| istio-gateway | `30080`, `30443`, `30520` | NodePort services |

### 4. DNS Resolution

The following hostnames must resolve to your cluster node IP (via DNS or `/etc/hosts` on client machines):

| Hostname | Purpose |
|----------|---------|
| `argocd.hanxux.local` | ArgoCD UI (via Istio Gateway) |
| `bookinfo.hanxux.local` | Bookinfo sample app |
| `jenkins.hanxux.local` | Jenkins UI (via ingress-nginx) |

### 5. Jenkins Node Dependencies

Jenkins agent pods mount host paths. Ensure the following are available on nodes where Jenkins runs:

- `/var/run/docker.sock` and `/usr/bin/docker` — Docker installed
- `/usr/bin/kubectl` — kubectl binary
- `/root/.kube` — kubeconfig configured

### 6. Image Registry Access

All images are pulled from the DaoCloud mirror (`m.daocloud.io`). Verify network connectivity:

```bash
curl -I https://m.daocloud.io
```

### 7. Cluster Resources

All components combined require approximately **1 GB+ memory**. Ensure your cluster has sufficient capacity.

## Deployment

### Quick Start

```bash
cd argocd/
chmod +x deploy.sh
./deploy.sh
```

The script will execute in order:
1. Create the AppProject (`appprj-default`)
2. Create ApplicationSets (Helm first, then Kustomize)

### Deployment Order

ArgoCD uses `syncWave` to control the deployment sequence:

| syncWave | Components |
|----------|------------|
| `-20` | cert-manager, ingress-nginx, istio-base, istiod, istio-gateway, jenkins, nfs-provisioner |
| `10` | bookinfo, istio-addons, argocd-istio |

Infrastructure (Helm) deploys first; applications (Kustomize) deploy after.

### Verify

```bash
kubectl -n argocd get applications
kubectl -n argocd describe application <app-name>
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Adding New Applications

### Add a Helm Chart App

```bash
mkdir -p helm-charts/my-app/charts

cat > helm-charts/my-app/app-config.yaml <<EOF
app:
  syncWave: "0"
  revision: main
  releaseName: my-app
  version: 1.0.0
  namespace: my-app
EOF

# Place your Helm chart files under helm-charts/my-app/charts/
```

### Add a Kustomize App

```bash
mkdir -p apps/base/my-app apps/overlays/my-app

# Create base resources and kustomization.yaml under apps/base/my-app/

cat > apps/overlays/my-app/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base/my-app
EOF
```

Push to `main` branch and ArgoCD will auto-detect and deploy.

## Private Repository Authentication

If your Git repository is **private**, you need to create a Kubernetes Secret so that ArgoCD can authenticate and pull the repo.

ArgoCD auto-discovers repositories by detecting Secrets with the label `argocd.argoproj.io/secret-type: repository`.

### Create a Repository Secret

```bash
kubectl create secret generic repo-my-private-repo \
  -n argocd \
  --from-literal=type=git \
  --from-literal=url=https://gitee.com/<owner>/<repo>.git \
  --from-literal=username=<github-username> \
  --from-literal=password=<github-pat> \
  --dry-run=client -o yaml \
  | kubectl label --local -f - \
      argocd.argoproj.io/secret-type=repository \
      --dry-run=client -o yaml \
  | kubectl apply -f -
```

Replace the placeholders:
- `repo-my-private-repo` — any unique Secret name
- `<owner>/<repo>` — your Gitee repository path
- `<github-username>` — your Gitee username
- `<github-pat>` — a Gitee Personal Access Token

### Verify

```bash
kubectl -n argocd get secret repo-my-private-repo \
  -o jsonpath='{.metadata.labels.argocd\.argoproj\.io/secret-type}'
# Expected output: repository
```

> **Note:** For SSH-based authentication, use `--from-literal=type=git` and `--from-literal=sshPrivateKey="$(cat ~/.ssh/id_rsa)"` instead of username/password. See the [ArgoCD Declarative Setup docs](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#repositories) for all options.
>
> The repository is hosted on Gitee (`https://gitee.com/hangxu969/local-k8s-gitops.git`) as a mirror for better network access in China.

## GitOps Workflow

1. Push config changes to the Git repo
2. ApplicationSet generators scan the repo and discover apps
3. ArgoCD auto-syncs changes to the cluster
4. Continuous health monitoring with auto-heal enabled
