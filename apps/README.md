# Kustomize 应用目录

本目录用于存放基于 Kustomize 的 Kubernetes 应用配置，通过 ArgoCD ApplicationSet 自动部署。

## 📁 目录结构

```
apps/
├── README.md                          # 本文档
├── base/                              # 基础配置目录
│   ├── kiali/                        # Kiali 应用基础配置
│   │   ├── namespace.yaml           # 命名空间定义
│   │   ├── deployment.yaml          # Deployment 配置
│   │   ├── service.yaml             # Service 配置
│   │   ├── configmap.yaml           # ConfigMap 配置
│   │   └── kustomization.yaml       # Kustomize 资源清单
│   └── jaeger/                       # Jaeger 应用基础配置
│       ├── namespace.yaml
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── configmap.yaml
│       └── kustomization.yaml
└── overlays/                          # 应用特定配置目录
    ├── kiali/
    │   ├── kustomization.yaml        # 引用 base 并应用补丁
    │   └── deployment-patch.yaml     # Deployment 补丁文件
    └── jaeger/
        ├── kustomization.yaml
        └── deployment-patch.yaml
```

## 🎯 设计理念

### Base 层（基础配置）
- **作用**：定义应用的通用配置，适用于所有环境
- **内容**：标准的 Kubernetes 资源清单（Deployment、Service、ConfigMap 等）
- **原则**：保持通用性，不包含环境特定的配置

### Overlays 层（应用配置）
- **作用**：在 base 基础上应用特定的配置
- **内容**：通过 Kustomize 的 patches 机制修改或扩展 base 配置
- **示例**：修改副本数、调整资源限制、添加环境变量、修改镜像标签

## 🚀 如何添加新应用

### 1. 创建 Base 配置

```bash
# 创建应用目录
mkdir -p apps/base/<app-name>

# 创建基础资源文件
cd apps/base/<app-name>
touch namespace.yaml deployment.yaml service.yaml kustomization.yaml
```

**kustomization.yaml 示例**：
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: <app-name>
resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
commonLabels:
  app: <app-name>
  managed-by: argocd
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
namespace: <app-name>
commonLabels:
  cluster: in-cluster
replicas:
  - name: <app-name>
    count: 1
```

### 3. ArgoCD 自动发现
配置完成后，ArgoCD ApplicationSet (`argocd/applicationsets/appset-kustomize.yaml`) 会自动扫描 `apps/overlays/` 目录并创建 Application。

## 🔧 本地验证

```bash
# 验证 base 配置
kustomize build apps/base/kiali

# 验证 overlay 配置
kustomize build apps/overlays/kiali

# 查看最终生成的 YAML
kustomize build apps/overlays/kiali | kubectl apply --dry-run=client -f -
```

## 📦 已部署应用

| 应用名称 | 命名空间 | 描述 |
|---------|---------|------|
| kiali   | kiali   | Istio 服务网格可视化工具 |
| jaeger  | jaeger  | 分布式追踪系统 |

## 🔗 ArgoCD 集成

### 查看部署状态
```bash
# 查看所有 Kustomize 应用
argocd app list -l deployment-type=kustomize

# 查看特定应用
argocd app get kiali

# 手动同步
argocd app sync kiali
```
