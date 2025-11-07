# local-k8s-gitops

基于 GitOps 理念的 Kubernetes 自动化部署平台，使用 Helm 和 ArgoCD 实现。

## 仓库结构

```
local-k8s-gitops/
├── helm-charts/               # Helm Charts 目录
│   ├── cert-manager/          # Cert-Manager Helm Chart
│   │   ├── app-config.yaml   # ArgoCD 应用配置
│   │   └── charts/           # Helm Chart 文件
│   ├── ingress-nginx/         # Ingress Nginx Helm Chart
│   ├── istio-base/            # Istio 基础组件
│   ├── istio-gateway/         # Istio Gateway
│   ├── istiod/                # Istio 控制平面
│   ├── jenkins/               # Jenkins CI/CD
│   └── nfs-provisioner/       # NFS 存储提供者
│
├── apps/                      # Kustomize 应用配置
│   ├── base/                  # 基础配置（环境无关）
│   │   ├── bookinfo/          # Bookinfo 示例应用
│   │   ├── istio-addons/      # Istio 可观测性组件
│   │   └── argocd-istio/      # ArgoCD Istio 集成
│   ├── overlays/              # 环境特定配置
│   │   ├── bookinfo/
│   │   ├── istio-addons/
│   │   └── argocd-istio/
│   └── README.md
│
├── argocd/                    # ArgoCD 配置
│   ├── projects/              # AppProject 定义
│   │   └── default-project.yaml
│   ├── applicationsets/       # ApplicationSet 定义
│   │   ├── appset-helm.yaml       # Helm Chart 应用集
│   │   └── appset-kustomize.yaml  # Kustomize 应用集
│   └── README.md
│
└── README.md
```

## 目录说明

### 📦 helm-charts/
存放 Helm Charts 配置，每个子目录代表一个应用。

**目录结构：**
- `app-config.yaml` - ArgoCD 应用配置（包含 syncWave、namespace、版本等元数据）
- `charts/` - Helm Chart 文件（Chart.yaml、values.yaml、templates/）

**已部署应用：**
- **cert-manager** - 自动化 TLS 证书管理
- **ingress-nginx** - Kubernetes Ingress 控制器
- **istio-base** - Istio 基础 CRD 和配置
- **istio-gateway** - Istio Ingress/Egress Gateway
- **istiod** - Istio 控制平面
- **jenkins** - CI/CD 平台
- **nfs-provisioner** - NFS 动态存储提供者

### 🚀 apps/
存放基于 Kustomize 的应用配置。

**已部署应用：**
- **bookinfo** - Istio 官方示例应用（微服务架构演示）
- **istio-addons** - Istio 可观测性组件（Grafana、Jaeger、Kiali、Prometheus）
- **argocd-istio** - ArgoCD 的 Istio Gateway 和 VirtualService 配置

详细说明请查看 [apps/README.md](./apps/README.md)

### 🔄 argocd/
存放 ArgoCD 的核心配置资源。

**projects/** - AppProject 资源定义
- `default-project.yaml` - 默认项目配置，管理所有应用的权限和部署策略

**applicationsets/** - ApplicationSet 资源定义
- `appset-helm.yaml` - 自动管理所有 Helm Chart 应用
- `appset-kustomize.yaml` - 自动管理所有 Kustomize 应用

## 快速开始

### 1. 添加 Helm Chart 应用

```bash
# 创建应用目录
mkdir -p helm-charts/my-app/charts

# 创建 app-config.yaml
cat > helm-charts/my-app/app-config.yaml <<EOF
app:
  syncWave: "0"
  revision: main
  releaseName: my-app
  version: 1.0.0
  namespace: my-app
EOF

# 创建或复制 Helm Chart 到 charts/ 目录
cd helm-charts/my-app/charts
helm create my-app
# 或者复制现有的 Helm Chart
```

### 2. 添加 Kustomize 应用

```bash
# 创建 base 配置
mkdir -p apps/base/my-app
cd apps/base/my-app
# 创建 Kubernetes 资源文件和 kustomization.yaml

# 创建 overlay 配置
mkdir -p apps/overlays/my-app
cat > apps/overlays/my-app/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base/my-app
EOF
```

### 3. 部署到集群

```bash
# 提交到 Git 仓库
git add .
git commit -m "Add my-app"
git push

# ArgoCD 会自动检测并部署应用
# 查看部署状态
kubectl --kubeconfig=<your-kubeconfig> get application -n argocd
```

## GitOps 工作流

1. **提交代码** - 将配置更改推送到 Git 仓库
2. **ArgoCD 检测** - ApplicationSet 自动扫描 Git 仓库，发现新应用或配置变更
3. **自动同步** - ArgoCD 自动将变更同步到 Kubernetes 集群
4. **健康检查** - 持续监控应用健康状态
5. **自动修复** - 如果集群中的资源被手动修改，ArgoCD 会自动恢复到 Git 中定义的状态

## 核心特性

### 🔄 ApplicationSet 自动化
- **Helm Charts**: `appset-helm.yaml` 自动扫描 `helm-charts/*/app-config.yaml`
- **Kustomize Apps**: `appset-kustomize.yaml` 自动扫描 `apps/overlays/*`
- 新增应用无需手动创建 Application，只需按规范创建目录结构

### 🎯 同步波次控制
通过 `syncWave` 注解控制应用部署顺序：
- `-20`: Istio 基础组件（istio-base）
- `-10`: Istio 控制平面（istiod）
- `0`: 其他基础设施和应用

### 🛡️ 忽略差异配置
针对 Istio Webhook 等动态资源配置 `ignoreDifferences`，避免误报 OutOfSync 状态

### 🔐 自动命名空间创建
配置了 `CreateNamespace=true`，应用部署时自动创建所需的命名空间

## 最佳实践

### Helm Charts
- ✅ 在 `app-config.yaml` 中定义应用元数据（syncWave、namespace、version）
- ✅ 使用 `values.yaml` 作为默认配置
- ✅ 使用 `values.dev.yaml` 等文件进行环境特定配置
- ✅ 合理设置 syncWave 确保依赖顺序正确

### Kustomize 应用
- ✅ Base 层保持通用性，包含完整的资源定义
- ✅ Overlay 层通过引用 base 实现复用
- ✅ 使用 patches 进行环境特定修改
- ✅ 保持目录结构清晰

### ArgoCD 配置
- ✅ 使用 ApplicationSet 实现应用自动发现和管理
- ✅ 配置 `ignoreDifferences` 处理动态资源
- ✅ 使用 `automated.prune` 和 `selfHeal` 保持集群状态一致
- ✅ 合理使用 AppProject 管理权限

### Git 工作流
- ✅ 使用有意义的提交信息
- ✅ 配置变更前先本地验证（kubectl apply --dry-run）
- ✅ 保持配置文件简洁可读，添加适当的注释

## 相关资源

- [Helm 官方文档](https://helm.sh/docs/)
- [ArgoCD 官方文档](https://argo-cd.readthedocs.io/)
- [Kustomize 官方文档](https://kustomize.io/)
- [Istio 官方文档](https://istio.io/latest/docs/)
- [GitOps 最佳实践](https://www.gitops.tech/)

## 常见问题

### 如何查看应用状态？
```bash
kubectl --kubeconfig=<your-kubeconfig> get application -n argocd
```

### 如何手动触发同步？
```bash
# 通过 kubectl
kubectl --kubeconfig=<your-kubeconfig> patch application <app-name> -n argocd \
  --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'

# 或通过 ArgoCD UI 点击 SYNC 按钮
```

### 应用显示 OutOfSync 怎么办？
1. 检查 Git 仓库和集群中的资源差异
2. 确认是否配置了 `ignoreDifferences`（针对动态资源）
3. 查看 ArgoCD Application 详情了解具体差异

### 如何调整应用部署顺序？
修改 `app-config.yaml` 中的 `syncWave` 值，数字越小越先部署
