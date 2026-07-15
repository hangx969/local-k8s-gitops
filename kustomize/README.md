# Kustomize Applications

Kustomize-based Kubernetes application configs, auto-deployed by ArgoCD ApplicationSet (`appset-kustomize.yaml`).

## Structure

```
kustomize/
├── base/                    # Base configs (environment-agnostic)
│   ├── bookinfo/            # Istio sample microservices app
│   ├── istio-addons/        # Grafana, Jaeger, Kiali, Prometheus
│   └── argocd-istio/        # ArgoCD Istio Gateway & VirtualService
└── overlays/                # Environment-specific overrides
    ├── bookinfo/            # Image mirror (DaoCloud) + version pinning
    ├── istio-addons/        # Image mirror + Service type → NodePort
    └── argocd-istio/        # Direct base reference (no overrides)
```

## How It Works

- **Base** defines complete, reusable resource manifests (Deployments, Services, Gateways, etc.)
- **Overlay** references a base and applies customizations (image replacements, patches, etc.)
- ArgoCD scans `kustomize/overlays/*` and generates one Application per subdirectory

## Adding a New App

```bash
# 1. Create base resources
mkdir -p kustomize/base/my-app
# Add deployment.yaml, service.yaml, kustomization.yaml, etc.

# 2. Create overlay
mkdir -p kustomize/overlays/my-app
cat > kustomize/overlays/my-app/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base/my-app
EOF

# 3. Push to main branch — ArgoCD auto-discovers and deploys
```

---
