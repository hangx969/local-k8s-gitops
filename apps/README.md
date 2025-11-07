# Kustomize 应用目录

本目录用于存放基于 Kustomize 的 Kubernetes 应用配置，通过 ArgoCD ApplicationSet 自动部署。

## 📁 目录结构

```
apps/
├── README.md                          # 本文档
├── base/                              # 基础配置目录
│   ├── bookinfo/                     # Bookinfo 示例应用
│   │   ├── bookinfo.yaml            # Bookinfo 应用定义
│   │   ├── bookinfo-gateway.yaml    # Istio Gateway 配置
│   │   ├── bookinfo-vs.yaml         # Istio VirtualService 配置
│   │   └── kustomization.yaml       # Kustomize 资源清单
│   ├── istio-addons/                 # Istio 可观测性组件
│   │   ├── grafana.yaml             # Grafana 配置
│   │   ├── jaeger.yaml              # Jaeger 配置
│   │   ├── kiali.yaml               # Kiali 配置
│   │   ├── prometheus.yaml          # Prometheus 配置
│   │   └── kustomization.yaml       # Kustomize 资源清单
│   └── argocd-istio/                 # ArgoCD Istio 集成
│       ├── argo-gateway.yaml        # ArgoCD Gateway 配置
│       ├── argo-vs.yaml             # ArgoCD VirtualService 配置
│       └── kustomization.yaml       # Kustomize 资源清单
└── overlays/                          # 环境特定配置目录
    ├── bookinfo/
    │   └── kustomization.yaml        # 引用 base 配置
    ├── istio-addons/
    │   └── kustomization.yaml        # 引用 base 配置
    └── argocd-istio/
        └── kustomization.yaml        # 引用 base 配置
```

## 🎯 设计理念

### Base 层（基础配置）
- **作用**：定义应用的通用配置，包含完整的 Kubernetes 资源清单
- **内容**：完整的应用部署所需的所有资源（Deployment、Service、Gateway、VirtualService 等）
- **原则**：保持配置的完整性和可重用性

### Overlays 层（环境配置）
- **作用**：引用 base 配置，可以通过 Kustomize patches 机制进行环境特定的修改
- **内容**：通过 `resources` 引用 base 配置，可选添加 patches 进行定制化
- **示例**：修改副本数、调整资源限制、添加环境变量、修改镜像标签

## 🚀 如何添加新应用

### 1. 创建 Base 配置

```bash
# 创建应用目录
mkdir -p apps/base/<app-name>

# 创建基础资源文件
cd apps/base/<app-name>
touch deployment.yaml service.yaml kustomization.yaml
```

**kustomization.yaml 示例**：
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: <app-namespace>

resources:
  - deployment.yaml
  - service.yaml
```

### 2. 创建 Overlay 配置

```bash
mkdir -p apps/overlays/<app-name>
cd apps/overlays/<app-name>
touch kustomization.yaml
```

**kustomization.yaml 示例**：
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base/<app-name>

# 可选：添加补丁或修改
# patchesStrategicMerge:
#   - deployment-patch.yaml
```

### 3. ArgoCD 自动发现
配置完成后，ArgoCD ApplicationSet (`argocd/applicationsets/appset-kustomize.yaml`) 会自动扫描 `apps/overlays/` 目录并创建 Application。

## 🔧 本地验证

```bash
# 验证 base 配置
kustomize build apps/base/bookinfo

# 验证 overlay 配置
kustomize build apps/overlays/bookinfo

# 查看最终生成的 YAML
kustomize build apps/overlays/bookinfo | kubectl apply --dry-run=client -f -
```

## 📦 已部署应用

| 应用名称 | 命名空间 | 描述 |
|---------|---------|------|
| bookinfo | bookinfo | Istio 官方示例应用（微服务架构演示） |
| istio-addons | istio-system | Istio 可观测性组件（Grafana、Jaeger、Kiali、Prometheus） |
| argocd-istio | argocd | ArgoCD 的 Istio Gateway 和 VirtualService 配置 |

## 🔗 ArgoCD 集成

### 查看部署状态
```bash
# 查看所有 Kustomize 应用
kubectl --kubeconfig=<your-kubeconfig> get application -n argocd

# 查看特定应用详情
kubectl --kubeconfig=<your-kubeconfig> get application bookinfo -n argocd -o yaml

# 通过 ArgoCD UI 查看
# 访问 ArgoCD Web 界面查看应用状态和同步情况
```

### 应用同步说明
- ApplicationSet `appset-kustomize` 会自动扫描 `apps/overlays/` 目录
- 每个 overlay 子目录会生成一个对应的 ArgoCD Application
- ArgoCD 会自动监控 Git 仓库变化并同步到集群
