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

---

## 🎯 设计理念

### Base 层（基础配置）
- **作用**：定义应用的通用配置，包含完整的 Kubernetes 资源清单
- **内容**：完整的应用部署所需的所有资源（Deployment、Service、Gateway、VirtualService 等）
- **原则**：保持配置的完整性和可重用性

### Overlays 层（环境配置）
- **作用**：引用 base 配置，可以通过 Kustomize patches 机制进行环境特定的修改
- **内容**：通过 `resources` 引用 base 配置，可选添加 patches 进行定制化
- **示例**：修改副本数、调整资源限制、添加环境变量、修改镜像标签

---

## 📘 Kustomization.yaml 深度解析

### Base 层 kustomization.yaml 的作用

Base 层的 `kustomization.yaml` 是 Kustomize 配置的核心，它定义了应用的基础资源集合。

**核心职责：**
1. **资源声明**：列出所有需要部署的 Kubernetes 资源文件
2. **命名空间管理**：为所有资源统一设置默认命名空间
3. **通用配置**：定义可被多个环境复用的基础配置
4. **资源组织**：将相关资源组织成一个逻辑单元

**实际示例（bookinfo base）：**
```yaml
# apps/base/bookinfo/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# 为所有资源设置统一命名空间
namespace: bookinfo

# 声明需要部署的资源文件
resources:
  - bookinfo.yaml           # 应用的核心资源（Deployments, Services）
  - bookinfo-gateway.yaml   # Istio Gateway 配置
  - bookinfo-vs.yaml        # Istio VirtualService 配置
```

**最佳实践：**
- ✅ Base 应该是完整且可独立部署的配置
- ✅ 包含应用运行的所有必需资源
- ✅ 使用通用的、环境无关的配置值
- ✅ 保持配置的可读性和维护性
- ❌ 不要包含环境特定的配置（如镜像源、副本数）
- ❌ 不要硬编码环境相关的值（如 NodePort 端口号）

### Overlay 层 kustomization.yaml 的作用

Overlay 层的 `kustomization.yaml` 通过引用 base 配置并应用特定修改，实现环境定制化。

**核心职责：**
1. **引用 Base**：通过 `resources` 字段引用基础配置
2. **环境定制**：应用环境特定的补丁和修改
3. **镜像替换**：修改容器镜像源、标签、版本
4. **配置覆盖**：调整副本数、资源限制、环境变量等

**实际示例 1：镜像替换（bookinfo overlay）**
```yaml
# apps/overlays/bookinfo/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# 引用基础配置（相对路径）
resources:
  - ../../base/bookinfo

# 镜像覆盖 - 使用国内镜像源加速拉取
images:
  # details 服务
  - name: docker.io/istio/examples-bookinfo-details-v1
    newName: m.daocloud.io/docker.io/istio/examples-bookinfo-details-v1
    newTag: "1.20.3"

  # productpage 服务
  - name: docker.io/istio/examples-bookinfo-productpage-v1
    newName: m.daocloud.io/docker.io/istio/examples-bookinfo-productpage-v1
    newTag: "1.20.3"
```

**实际示例 2：JSON Patch 补丁（istio-addons overlay）**
```yaml
# apps/overlays/istio-addons/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base/istio-addons

# 镜像覆盖
images:
  - name: docker.io/grafana/grafana
    newName: m.daocloud.io/docker.io/grafana/grafana
    newTag: "11.3.1"

# JSON Patch - 精确修改特定字段
patches:
  # 将 Grafana Service 类型改为 NodePort
  - target:
      kind: Service
      name: grafana
    patch: |-
      - op: replace
        path: /spec/type
        value: NodePort

  # 将 Prometheus Service 类型改为 NodePort
  - target:
      kind: Service
      name: prometheus
    patch: |-
      - op: replace
        path: /spec/type
        value: NodePort
```

**实际示例 3：简单引用（argocd-istio overlay）**
```yaml
# apps/overlays/argocd-istio/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# 仅引用 base，不做额外修改
# 适用于 base 配置已经满足需求的场景
resources:
  - ../../base/argocd-istio
```

### Base 与 Overlay 的协同工作机制

```
┌─────────────────────────────────────────────────────────────┐
│                     Kustomize 构建流程                        │
└─────────────────────────────────────────────────────────────┘

1. 读取 Overlay kustomization.yaml
   ↓
2. 解析 resources 字段，找到 base 目录
   ↓
3. 加载 base/kustomization.yaml 及其声明的所有资源
   ↓
4. 应用 overlay 中的转换操作：
   ├─ images: 替换镜像名称和标签
   ├─ patches: 应用 JSON/Strategic Merge Patch
   ├─ replicas: 修改副本数
   ├─ configMapGenerator: 生成 ConfigMap
   └─ secretGenerator: 生成 Secret
   ↓
5. 输出最终的 Kubernetes YAML 资源清单
```

**工作原理示例：**
```bash
# Base 配置（原始镜像）
# base/bookinfo/bookinfo.yaml
containers:
  - name: details
    image: docker.io/istio/examples-bookinfo-details-v1:1.18.0

# Overlay 配置（镜像替换规则）
# overlays/bookinfo/kustomization.yaml
images:
  - name: docker.io/istio/examples-bookinfo-details-v1
    newName: m.daocloud.io/docker.io/istio/examples-bookinfo-details-v1
    newTag: "1.20.3"

# 最终生成的配置
# kustomize build overlays/bookinfo
containers:
  - name: details
    image: m.daocloud.io/docker.io/istio/examples-bookinfo-details-v1:1.20.3
```

---

## 🏗️ DevOps 最佳实践

### 1. Base 配置结构最佳实践

**✅ 应该包含的内容：**
```yaml
# 完整的应用定义
resources:
  - deployment.yaml        # 工作负载定义
  - service.yaml          # 服务暴露
  - configmap.yaml        # 通用配置（可选）
  - serviceaccount.yaml   # 服务账号（如需要）
  - rbac.yaml             # RBAC 权限（如需要）

# 统一的命名空间
namespace: my-app

# 通用标签（推荐）
commonLabels:
  app.kubernetes.io/name: my-app
  app.kubernetes.io/managed-by: kustomize

# 通用注解（可选）
commonAnnotations:
  version: "1.0.0"
  team: "platform-team"
```

**❌ 不应该包含的内容：**
- 环境特定的镜像标签（应在 overlay 中指定）
- 特定环境的资源限制（应在 overlay 中调整）
- NodePort 等环境相关的 Service 类型（应在 overlay 中修改）
- 特定环境的副本数（应在 overlay 中覆盖）

**组织建议：**
```
base/my-app/
├── kustomization.yaml          # 主配置文件
├── deployment.yaml             # 核心工作负载
├── service.yaml                # 服务定义
├── configmap.yaml              # 配置数据
└── components/                 # 可选组件（高级用法）
    ├── monitoring/
    │   └── servicemonitor.yaml
    └── ingress/
        └── ingress.yaml
```

### 2. Overlay 配置策略

#### 策略 1：镜像管理
```yaml
# 使用 images 字段替换镜像（推荐方式）
images:
  - name: nginx                    # 原始镜像名
    newName: harbor.example.com/library/nginx  # 新镜像仓库
    newTag: "1.24-alpine"          # 新标签

  # 支持 digest 固定（生产环境推荐）
  - name: redis
    newName: harbor.example.com/library/redis
    digest: sha256:abc123...       # 使用 digest 确保镜像不可变
```

#### 策略 2：Strategic Merge Patch
```yaml
# 适用于简单的字段修改和添加
patchesStrategicMerge:
  - |-
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-app
    spec:
      replicas: 3                  # 修改副本数
      template:
        spec:
          containers:
          - name: my-app
            resources:             # 添加资源限制
              requests:
                memory: "256Mi"
                cpu: "100m"
              limits:
                memory: "512Mi"
                cpu: "200m"
```

#### 策略 3：JSON Patch
```yaml
# 适用于精确的字段替换、删除操作
patches:
  # 替换操作
  - target:
      kind: Service
      name: my-service
    patch: |-
      - op: replace
        path: /spec/type
        value: NodePort

  # 添加操作
  - target:
      kind: Deployment
      name: my-app
    patch: |-
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: ENVIRONMENT
          value: production

  # 删除操作
  - target:
      kind: Deployment
      name: my-app
    patch: |-
      - op: remove
        path: /spec/template/spec/containers/0/env/0
```

#### Strategic Merge Patch vs JSON Patch 选择指南

| 场景 | 推荐方式 | 原因 |
|------|---------|------|
| 修改简单字段（副本数、镜像） | Strategic Merge | 语法简单，易读易维护 |
| 精确替换特定值 | JSON Patch | 明确的操作语义，避免合并冲突 |
| 添加数组元素 | JSON Patch | 精确控制添加位置 |
| 删除字段 | JSON Patch | Strategic Merge 不支持删除 |
| 复杂的嵌套结构修改 | JSON Patch | 路径表达式更精确 |
| 跨多个资源的通用修改 | Strategic Merge | 可以一次性修改多个资源 |

### 3. 命名空间管理策略

```yaml
# 方式 1：在 base 中定义（推荐）
# base/kustomization.yaml
namespace: my-app

# 方式 2：在 overlay 中覆盖
# overlays/production/kustomization.yaml
namespace: my-app-prod           # 覆盖 base 的命名空间

# 方式 3：为不同资源设置不同命名空间
# overlays/multi-namespace/kustomization.yaml
patches:
  - target:
      kind: Deployment
      name: app-backend
    patch: |-
      - op: replace
        path: /metadata/namespace
        value: backend-ns
```

### 4. ConfigMap 和 Secret 管理

```yaml
# 使用 Generator 自动生成（推荐）
configMapGenerator:
  - name: app-config
    files:
      - config/app.properties
      - config/logging.conf
    literals:
      - LOG_LEVEL=info
      - MAX_CONNECTIONS=100
    options:
      disableNameSuffixHash: false  # 自动添加 hash 后缀，配置变更时触发滚动更新

secretGenerator:
  - name: app-secrets
    files:
      - secrets/db-password.txt
    literals:
      - API_KEY=xyz123
    type: Opaque
    options:
      disableNameSuffixHash: false

# 使用外部 Secret 管理工具（生产环境推荐）
# - Sealed Secrets
# - External Secrets Operator
# - SOPS (Secret Operations)
```

### 5. 标签和注解策略

```yaml
# 通用标签 - 自动添加到所有资源
commonLabels:
  app.kubernetes.io/name: my-app
  app.kubernetes.io/instance: my-app-prod
  app.kubernetes.io/version: "1.2.3"
  app.kubernetes.io/component: backend
  app.kubernetes.io/part-of: my-platform
  app.kubernetes.io/managed-by: argocd

# 通用注解
commonAnnotations:
  # 责任团队
  team: "platform-team"
  # 联系方式
  contact: "platform-team@example.com"
  # 文档链接
  documentation: "https://docs.example.com/my-app"
  # 变更追踪
  change-id: "CHG-2024-001"

# 特定资源的标签（使用 patch）
patches:
  - target:
      kind: Deployment
      name: my-app
    patch: |-
      - op: add
        path: /spec/template/metadata/labels/monitoring
        value: "enabled"
```

### 6. 资源命名规范

**推荐规范：**
```
{app-name}-{component}-{resource-type}

示例：
- Deployment: bookinfo-details-deployment
- Service: bookinfo-details-service
- ConfigMap: bookinfo-config
- Secret: bookinfo-secrets
```

**Base 中使用简单名称：**
```yaml
# base/deployment.yaml
metadata:
  name: my-app              # 简单名称

# overlay 中添加前缀/后缀
# overlays/production/kustomization.yaml
namePrefix: prod-           # 最终: prod-my-app
nameSuffix: -v2             # 最终: my-app-v2
```

### 7. 版本控制最佳实践

**Git 提交规范：**
```bash
# 使用语义化的提交信息
git commit -m "feat(bookinfo): add resource limits to details service"
git commit -m "fix(istio-addons): correct grafana service type to NodePort"
git commit -m "chore(overlays): update image tags to 1.20.3"

# 使用 Git tags 标记重要版本
git tag -a v1.0.0 -m "Initial production release"
git tag -a v1.1.0 -m "Add monitoring components"
```

**变更追踪：**
```yaml
# 在 kustomization.yaml 中记录变更
commonAnnotations:
  version: "1.2.3"
  changelog: "Updated Grafana to 11.3.1, added resource limits"
  last-updated: "2024-11-29"
  updated-by: "platform-team"
```

---

## 🎨 常见模式与反模式

### ✅ 推荐模式

#### 模式 1：单一 Base，多环境 Overlays
```
apps/
├── base/my-app/              # 单一 base
│   └── kustomization.yaml
└── overlays/
    ├── dev/                  # 开发环境
    │   └── kustomization.yaml
    ├── staging/              # 预发布环境
    │   └── kustomization.yaml
    └── production/           # 生产环境
        └── kustomization.yaml
```

**优势：**
- DRY 原则：配置不重复
- 变更传播：base 的修改自动影响所有环境
- 易于维护：集中管理通用配置

#### 模式 2：使用 Components 实现可选功能
```yaml
# base/kustomization.yaml
resources:
  - deployment.yaml
  - service.yaml

# components/monitoring/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

resources:
  - servicemonitor.yaml
  - prometheusrule.yaml

# overlays/production/kustomization.yaml
resources:
  - ../../base

components:
  - ../../components/monitoring    # 生产环境启用监控
  - ../../components/autoscaling   # 生产环境启用自动扩缩容
```

#### 模式 3：使用 Generators 管理配置
```yaml
# 从文件生成 ConfigMap
configMapGenerator:
  - name: app-config
    files:
      - configs/application.yaml
      - configs/database.yaml

# 配置文件变更时，hash 后缀会改变
# 触发 Pod 自动滚动更新
# ConfigMap 名称: app-config-d2g89h7mhf
```

#### 模式 4：镜像版本管理
```yaml
# 方式 1：使用 digest（最安全）
images:
  - name: nginx
    newName: harbor.example.com/library/nginx
    digest: sha256:abc123...

# 方式 2：使用固定标签（推荐）
images:
  - name: nginx
    newName: harbor.example.com/library/nginx
    newTag: "1.24.0"

# 方式 3：使用变量（需要外部工具支持）
# 配合 ArgoCD 的 Image Updater
images:
  - name: my-app
    newTag: "${APP_VERSION}"
```

### ❌ 反模式

#### 反模式 1：在 Base 中硬编码环境相关配置
```yaml
# ❌ 不好的做法
# base/deployment.yaml
spec:
  replicas: 3                    # 硬编码副本数
  template:
    spec:
      containers:
      - image: nginx:1.24.0      # 硬编码镜像版本
        env:
        - name: ENVIRONMENT
          value: production      # 硬编码环境变量

# ✅ 正确做法：base 使用通用配置
spec:
  replicas: 1                    # 默认最小值
  template:
    spec:
      containers:
      - image: nginx:latest      # 使用通用标签
        # 环境变量在 overlay 中通过 patch 添加
```

#### 反模式 2：过度使用 Patch
```yaml
# ❌ 不好的做法：大量 patch 修改
patches:
  - patch: |-
      # 100+ 行的 patch 内容
      # 几乎重写了整个资源定义

# ✅ 正确做法：考虑创建新的 base
# 如果 patch 内容过多，说明 base 设计不合理
# 应该重新设计 base 或创建多个 base
```

#### 反模式 3：忽略命名空间管理
```yaml
# ❌ 不好的做法：在资源文件中硬编码 namespace
# base/deployment.yaml
metadata:
  namespace: my-app             # 硬编码

# ✅ 正确做法：在 kustomization.yaml 中统一管理
# base/kustomization.yaml
namespace: my-app               # 统一设置
```

#### 反模式 4：复制粘贴 Base
```
# ❌ 不好的做法
apps/
├── base/
│   ├── my-app-dev/            # 为每个环境创建 base
│   ├── my-app-staging/
│   └── my-app-prod/

# ✅ 正确做法
apps/
├── base/my-app/               # 单一 base
└── overlays/
    ├── dev/
    ├── staging/
    └── production/
```

#### 反模式 5：不使用 commonLabels
```yaml
# ❌ 不好的做法：在每个资源中手动添加标签
# 导致标签不一致，难以管理

# ✅ 正确做法：使用 commonLabels
commonLabels:
  app: my-app
  team: platform
  managed-by: kustomize
```

---

## 🔍 多环境部署策略

### 策略 1：基于目录的环境隔离
```
overlays/
├── dev/
│   ├── kustomization.yaml
│   ├── replicas-patch.yaml     # 开发环境 1 副本
│   └── resources-patch.yaml    # 开发环境资源限制较小
├── staging/
│   ├── kustomization.yaml
│   ├── replicas-patch.yaml     # 预发布 2 副本
│   └── resources-patch.yaml    # 预发布环境资源适中
└── production/
    ├── kustomization.yaml
    ├── replicas-patch.yaml     # 生产环境 5 副本
    ├── resources-patch.yaml    # 生产环境资源充足
    ├── hpa.yaml                # 生产环境启用 HPA
    └── pdb.yaml                # 生产环境启用 PDB
```

### 策略 2：基于配置的环境差异
```yaml
# overlays/dev/kustomization.yaml
resources:
  - ../../base/my-app

# 开发环境：使用 latest 标签，快速迭代
images:
  - name: my-app
    newTag: latest

replicas:
  - name: my-app
    count: 1

# overlays/production/kustomization.yaml
resources:
  - ../../base/my-app

# 生产环境：使用固定版本，确保稳定性
images:
  - name: my-app
    newTag: "v1.2.3"
    digest: sha256:abc123...

replicas:
  - name: my-app
    count: 5

patches:
  # 生产环境添加资源限制
  - target:
      kind: Deployment
    patch: |-
      - op: add
        path: /spec/template/spec/containers/0/resources
        value:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
```

### 策略 3：配置漂移预防
```yaml
# 使用 ArgoCD 的自动同步和 self-heal
# argocd/applications/my-app-prod.yaml
spec:
  syncPolicy:
    automated:
      prune: true       # 自动删除集群中多余的资源
      selfHeal: true    # 自动修复配置漂移
    syncOptions:
      - CreateNamespace=true
      - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

---

## 🚀 如何添加新应用

### 1. 创建 Base 配置

```bash
# 创建应用目录
mkdir -p apps/base/<app-name>
cd apps/base/<app-name>

# 创建基础资源文件
touch deployment.yaml service.yaml kustomization.yaml
```

**kustomization.yaml 模板**：
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# 设置命名空间
namespace: <app-namespace>

# 添加通用标签
commonLabels:
  app.kubernetes.io/name: <app-name>
  app.kubernetes.io/managed-by: kustomize

# 声明资源文件
resources:
  - deployment.yaml
  - service.yaml
  # - configmap.yaml         # 如需要
  # - serviceaccount.yaml    # 如需要
  # - ingress.yaml          # 如需要
```

**deployment.yaml 模板**：
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <app-name>
spec:
  replicas: 1
  selector:
    matchLabels:
      app: <app-name>
  template:
    metadata:
      labels:
        app: <app-name>
    spec:
      containers:
      - name: <app-name>
        image: <image-name>:latest
        ports:
        - containerPort: 8080
        # 建议在 overlay 中添加资源限制
```

### 2. 创建 Overlay 配置

```bash
mkdir -p apps/overlays/<app-name>
cd apps/overlays/<app-name>
touch kustomization.yaml
```

**kustomization.yaml 模板（基础版）**：
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# 引用 base 配置
resources:
  - ../../base/<app-name>

# 镜像替换（如需要）
images:
  - name: <image-name>
    newName: <registry>/<image-name>
    newTag: "<version>"

# 副本数调整（如需要）
replicas:
  - name: <app-name>
    count: 3
```

**kustomization.yaml 模板（完整版）**：
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base/<app-name>

# 镜像管理
images:
  - name: <image-name>
    newName: harbor.example.com/library/<image-name>
    newTag: "1.0.0"

# 副本数
replicas:
  - name: <app-name>
    count: 3

# ConfigMap 生成
configMapGenerator:
  - name: <app-name>-config
    literals:
      - LOG_LEVEL=info
      - MAX_CONNECTIONS=100

# JSON Patch
patches:
  # 修改 Service 类型为 NodePort
  - target:
      kind: Service
      name: <app-name>
    patch: |-
      - op: replace
        path: /spec/type
        value: NodePort

  # 添加资源限制
  - target:
      kind: Deployment
      name: <app-name>
    patch: |-
      - op: add
        path: /spec/template/spec/containers/0/resources
        value:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
```

### 3. ArgoCD 自动发现

配置完成后，ArgoCD ApplicationSet (`argocd/applicationsets/appset-kustomize.yaml`) 会自动扫描 `apps/overlays/` 目录并创建 Application。

**验证自动发现：**
```bash
# 查看 ApplicationSet 生成的 Applications
kubectl --kubeconfig=<your-kubeconfig> get application -n argocd

# 预期输出：
# NAME              SYNC STATUS   HEALTH STATUS
# bookinfo          Synced        Healthy
# istio-addons      Synced        Healthy
# argocd-istio      Synced        Healthy
# <app-name>        OutOfSync     Unknown      # 新添加的应用
```

---

## 🔧 本地验证

### 基础验证命令

```bash
# 1. 验证 base 配置语法
kustomize build apps/base/bookinfo

# 2. 验证 overlay 配置语法
kustomize build apps/overlays/bookinfo

# 3. 检查最终生成的 YAML（不实际应用）
kustomize build apps/overlays/bookinfo | kubectl apply --dry-run=client -f -

# 4. 服务端验证（检查是否会被 Admission Controller 拒绝）
kustomize build apps/overlays/bookinfo | kubectl apply --dry-run=server -f -

# 5. 查看差异对比
kustomize build apps/overlays/bookinfo > /tmp/current.yaml
# 修改配置后
kustomize build apps/overlays/bookinfo > /tmp/new.yaml
diff /tmp/current.yaml /tmp/new.yaml
```

### 高级验证技巧

```bash
# 验证特定资源
kustomize build apps/overlays/bookinfo | kubectl apply --dry-run=client -f - | grep -A 20 "kind: Deployment"

# 验证镜像是否正确替换
kustomize build apps/overlays/bookinfo | grep "image:"

# 验证标签是否正确添加
kustomize build apps/overlays/bookinfo | grep -A 5 "labels:"

# 使用 kubeconform 进行 schema 验证（推荐）
kustomize build apps/overlays/bookinfo | kubeconform -strict -summary

# 使用 kubeval 验证（备选方案）
kustomize build apps/overlays/bookinfo | kubeval --strict

# 使用 kustomize 内置验证
cd apps/overlays/bookinfo
kustomize build --enable-alpha-plugins --enable-helm
```

### 集成 CI/CD 验证

**GitHub Actions 示例：**
```yaml
name: Validate Kustomize

on:
  pull_request:
    paths:
      - 'apps/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Kustomize
        uses: imranismail/setup-kustomize@v2

      - name: Validate all overlays
        run: |
          for overlay in apps/overlays/*/; do
            echo "Validating $overlay"
            kustomize build "$overlay" | kubectl apply --dry-run=client -f -
          done

      - name: Check for image tags
        run: |
          # 确保生产环境不使用 latest 标签
          if kustomize build apps/overlays/production | grep -q "image:.*:latest"; then
            echo "ERROR: Production should not use :latest tag"
            exit 1
          fi
```

---

## 📦 已部署应用

| 应用名称 | 命名空间 | 描述 | Base 特点 | Overlay 定制 |
|---------|---------|------|-----------|-------------|
| bookinfo | bookinfo | Istio 官方示例应用（微服务架构演示） | 完整的微服务应用定义 + Istio 流量管理 | 镜像源替换（DaoCloud）+ 版本固定 |
| istio-addons | istio-system | Istio 可观测性组件（Grafana、Jaeger、Kiali、Prometheus） | 标准的 Istio 插件配置 | 镜像源替换 + Service 类型改为 NodePort |
| argocd-istio | argocd | ArgoCD 的 Istio Gateway 和 VirtualService 配置 | Istio 流量管理资源 | 无额外定制（直接使用 base） |

---

## 🔗 ArgoCD 集成

### 查看部署状态

```bash
# 查看所有 Kustomize 应用
kubectl --kubeconfig=<your-kubeconfig> get application -n argocd

# 查看特定应用详情
kubectl --kubeconfig=<your-kubeconfig> get application bookinfo -n argocd -o yaml

# 查看应用同步状态
kubectl --kubeconfig=<your-kubeconfig> get application bookinfo -n argocd -o jsonpath='{.status.sync.status}'

# 查看应用健康状态
kubectl --kubeconfig=<your-kubeconfig> get application bookinfo -n argocd -o jsonpath='{.status.health.status}'

# 通过 ArgoCD UI 查看
# 访问 ArgoCD Web 界面查看应用状态和同步情况
```

### 应用同步说明

- ApplicationSet `appset-kustomize` 会自动扫描 `apps/overlays/` 目录
- 每个 overlay 子目录会生成一个对应的 ArgoCD Application
- ArgoCD 会自动监控 Git 仓库变化并同步到集群
- 默认同步策略：手动同步（可在 ApplicationSet 中配置自动同步）

### 手动同步操作

```bash
# 同步单个应用
kubectl --kubeconfig=<your-kubeconfig> -n argocd patch application bookinfo -p '{"metadata": {"annotations": {"argocd.argoproj.io/refresh": "hard"}}}' --type merge

# 或使用 ArgoCD CLI
argocd app sync bookinfo

# 同步并等待完成
argocd app sync bookinfo --wait

# 硬刷新（重新从 Git 拉取）
argocd app sync bookinfo --force
```

---

## 🐛 常见问题排查

### 问题 1：Kustomize build 失败

**错误信息：**
```
Error: unable to find one of 'kustomization.yaml', 'kustomization.yml' or 'Kustomization'
```

**原因：**
- kustomization.yaml 文件不存在
- 文件名拼写错误（注意大小写）

**解决方案：**
```bash
# 检查文件是否存在
ls -la apps/overlays/my-app/

# 确保文件名正确
# 支持的文件名：kustomization.yaml, kustomization.yml, Kustomization
```

### 问题 2：资源引用路径错误

**错误信息：**
```
Error: accumulating resources: accumulation err='accumulating resources from '../../base/my-app':
evalsymlink failure on '/path/to/base/my-app'
```

**原因：**
- resources 字段中的相对路径不正确
- base 目录不存在

**解决方案：**
```yaml
# 检查相对路径是否正确
# overlays/my-app/kustomization.yaml
resources:
  - ../../base/my-app    # 确保路径正确

# 验证路径
cd apps/overlays/my-app
ls -la ../../base/my-app/
```

### 问题 3：镜像替换不生效

**症状：**
- kustomize build 后镜像仍然是原始镜像
- 镜像名称不匹配

**原因：**
- images 字段的 name 必须与 base 中的镜像名完全匹配
- 大小写敏感

**解决方案：**
```yaml
# 检查 base 中的镜像名
# base/deployment.yaml
containers:
  - image: docker.io/istio/examples-bookinfo-details-v1:1.18.0
         # ↑ 必须完全匹配

# overlays/kustomization.yaml
images:
  - name: docker.io/istio/examples-bookinfo-details-v1  # 完全匹配（不含标签）
    newName: m.daocloud.io/docker.io/istio/examples-bookinfo-details-v1
    newTag: "1.20.3"
```

### 问题 4：JSON Patch 路径错误

**错误信息：**
```
Error: failed to patch target: add operation does not apply: doc is missing path
```

**原因：**
- JSON Patch 路径不存在
- 数组索引越界

**解决方案：**
```yaml
# 错误示例
patches:
  - target:
      kind: Deployment
    patch: |-
      - op: add
        path: /spec/template/spec/containers/0/env/-   # 如果 env 不存在会报错
        value:
          name: NEW_VAR

# 正确做法 1：先创建 env 数组
patches:
  - target:
      kind: Deployment
    patch: |-
      - op: add
        path: /spec/template/spec/containers/0/env
        value: []
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: NEW_VAR

# 正确做法 2：使用 Strategic Merge Patch
patchesStrategicMerge:
  - |-
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-app
    spec:
      template:
        spec:
          containers:
          - name: my-app
            env:
            - name: NEW_VAR
              value: "value"
```

### 问题 5：命名空间冲突

**症状：**
- 资源部署到错误的命名空间
- 多个命名空间定义冲突

**原因：**
- base 和 overlay 中都定义了 namespace
- 资源文件中硬编码了 namespace

**解决方案：**
```yaml
# 最佳实践：只在 base/kustomization.yaml 中定义
# base/kustomization.yaml
namespace: my-app

# overlay/kustomization.yaml
# 不要重复定义 namespace（除非需要覆盖）

# 如果需要覆盖命名空间
# overlay/production/kustomization.yaml
namespace: my-app-prod    # 覆盖 base 的 my-app
```

### 问题 6：ArgoCD 不自动发现新应用

**症状：**
- 在 `apps/overlays/` 下创建了新应用
- ArgoCD 没有自动生成 Application

**原因：**
- ApplicationSet 的 git 目录匹配规则不匹配
- ApplicationSet 刷新间隔未到

**解决方案：**
```bash
# 1. 检查 ApplicationSet 配置
kubectl --kubeconfig=<your-kubeconfig> get applicationset -n argocd appset-kustomize -o yaml

# 2. 手动触发 ApplicationSet 刷新
kubectl --kubeconfig=<your-kubeconfig> -n argocd patch applicationset appset-kustomize \
  -p '{"metadata": {"annotations": {"argocd.argoproj.io/refresh": "hard"}}}' --type merge

# 3. 检查目录结构是否符合 ApplicationSet 的 path 规则
# 预期：apps/overlays/*/kustomization.yaml

# 4. 查看 ApplicationSet 控制器日志
kubectl --kubeconfig=<your-kubeconfig> logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller
```

### 问题 7：ConfigMap/Secret 未触发滚动更新

**症状：**
- 修改了 ConfigMap 内容
- Pod 没有重启，仍使用旧配置

**原因：**
- ConfigMap 名称没有变化
- Pod 不会自动检测 ConfigMap 内容变更

**解决方案：**
```yaml
# 使用 configMapGenerator 并启用 hash 后缀
configMapGenerator:
  - name: app-config
    files:
      - config.yaml
    options:
      disableNameSuffixHash: false  # 启用 hash 后缀（默认）

# 每次配置变更时，ConfigMap 名称会改变：
# app-config-d2g89h7mhf -> app-config-k8s9f5d2hf
# 引用此 ConfigMap 的 Deployment 会自动触发滚动更新
```

### 问题 8：patch 未生效

**症状：**
- 添加了 patch
- kustomize build 后配置未改变

**原因：**
- target 选择器不匹配
- patch 格式错误

**解决方案：**
```yaml
# 调试技巧 1：验证 target 是否匹配
kustomize build apps/overlays/my-app | grep -A 20 "kind: Service"

# 调试技巧 2：检查 patch 格式
patches:
  - target:
      kind: Service
      name: my-service     # 必须与实际资源名匹配
      namespace: my-app    # 可选，如果指定必须匹配
    patch: |-
      - op: replace
        path: /spec/type
        value: NodePort

# 调试技巧 3：使用 labelSelector 匹配多个资源
patches:
  - target:
      kind: Deployment
      labelSelector: "app=my-app"  # 匹配所有带此标签的 Deployment
    patch: |-
      - op: add
        path: /spec/template/spec/containers/0/resources
        value:
          limits:
            memory: "1Gi"
```

---

## 🎓 学习资源

### 官方文档
- [Kustomize 官方文档](https://kustomize.io/)
- [Kustomize GitHub](https://github.com/kubernetes-sigs/kustomize)
- [Kubernetes Kustomize 教程](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)

### 最佳实践指南
- [Kustomize Best Practices](https://kubectl.docs.kubernetes.io/references/kustomize/glossary/)
- [ArgoCD Kustomize Integration](https://argo-cd.readthedocs.io/en/stable/user-guide/kustomize/)

### 社区案例
- [Kubernetes Examples](https://github.com/kubernetes/examples)
- [Kustomize Examples](https://github.com/kubernetes-sigs/kustomize/tree/master/examples)

---
