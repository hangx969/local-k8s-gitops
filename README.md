# local-k8s-gitops

基于 GitOps 理念的 Kubernetes 自动化部署平台，使用 Helm 和 ArgoCD 实现。

## 仓库结构

```
local-k8s-gitops/
├── charts/                    # 自定义 Helm Charts
│   ├── app-name/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   └── README.md
│
├── apps/                      # 应用配置文件
│   ├── base/                  # 基础配置（环境无关）
│   │   └── app-name/
│   ├── overlays/              # 环境特定配置
│   │   ├── dev/               # 开发环境
│   │   ├── staging/           # 预发布环境
│   │   └── prod/              # 生产环境
│   └── README.md
│
├── argocd/                    # ArgoCD 配置
│   ├── projects/              # AppProject 定义
│   │   ├── project-name.yaml
│   │   └── README.md
│   ├── applicationsets/       # ApplicationSet 定义
│   │   ├── appset-name.yaml
│   │   └── README.md
│   └── README.md
│
└── README.md
```

## 目录说明

### 📦 charts/
存放自定义的 Helm Charts，用于打包和部署 Kubernetes 应用。

**使用场景：**
- 需要自定义的应用配置
- 需要版本化管理的应用
- 可复用的应用模板

详细说明请查看 [charts/README.md](./charts/README.md)

### 🚀 apps/
存放应用的配置文件，支持 Kustomize 或纯 YAML 方式。

**使用场景：**
- 使用第三方 Helm Charts 时的 values 文件
- Kustomize 配置
- 环境特定的配置覆盖

详细说明请查看 [apps/README.md](./apps/README.md)

### 🔄 argocd/
存放 ArgoCD 的核心配置资源。

**projects/** - AppProject 资源定义
- 用于对 Applications 进行逻辑分组
- 配置访问权限和部署策略
- 详细说明请查看 [argocd/projects/README.md](./argocd/projects/README.md)

**applicationsets/** - ApplicationSet 资源定义
- 自动化生成和管理多个 Applications
- 支持多集群、多环境部署
- 详细说明请查看 [argocd/applicationsets/README.md](./argocd/applicationsets/README.md)

## 快速开始

### 1. 添加自定义 Helm Chart

```bash
cd charts
helm create my-app
# 编辑 Chart.yaml 和 values.yaml
```

### 2. 添加应用配置

```bash
# 创建基础配置
mkdir -p apps/base/my-app

# 创建环境特定配置
mkdir -p apps/overlays/prod/my-app
```

### 3. 创建 ArgoCD AppProject

```bash
# 在 argocd/projects/ 目录创建 YAML 文件
kubectl apply -f argocd/projects/my-project.yaml
```

### 4. 创建 ArgoCD ApplicationSet

```bash
# 在 argocd/applicationsets/ 目录创建 YAML 文件
kubectl apply -f argocd/applicationsets/my-appset.yaml
```

## GitOps 工作流

1. **提交代码** - 将配置更改推送到 Git 仓库
2. **ArgoCD 同步** - ArgoCD 检测到更改并自动同步
3. **部署应用** - 应用被部署到 Kubernetes 集群
4. **监控状态** - 通过 ArgoCD UI 监控部署状态

## 最佳实践

- ✅ 使用有意义的命名约定
- ✅ 为不同环境使用 overlays
- ✅ 在 AppProject 中限制权限范围
- ✅ 使用 ApplicationSet 自动化管理
- ✅ 保持配置文件简洁可读
- ✅ 添加适当的注释和文档

## 相关资源

- [Helm 官方文档](https://helm.sh/docs/)
- [ArgoCD 官方文档](https://argo-cd.readthedocs.io/)
- [Kustomize 官方文档](https://kustomize.io/)
- [GitOps 最佳实践](https://www.gitops.tech/)
