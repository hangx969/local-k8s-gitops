# ArgoCD ApplicationSets

本目录存放 ArgoCD ApplicationSet 资源定义。

## 什么是 ApplicationSet？

ApplicationSet 是一个 Kubernetes CRD，用于自动化生成和管理多个 ArgoCD Applications。它特别适合：

- 部署到多个集群
- 从单个仓库部署多个应用
- 使用模板化的方式管理大量相似的应用

## 主要生成器类型

### 1. List Generator
基于列表生成 Applications

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: app-list
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - cluster: dev
        url: https://dev.example.com
      - cluster: prod
        url: https://prod.example.com
  template:
    metadata:
      name: 'myapp-{{cluster}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/hangx969/local-k8s-gitops
        targetRevision: HEAD
        path: apps/overlays/{{cluster}}/myapp
      destination:
        server: '{{url}}'
        namespace: myapp
```

### 2. Git Directory Generator
基于 Git 仓库目录结构生成 Applications

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: apps-directory
  namespace: argocd
spec:
  generators:
  - git:
      repoURL: https://github.com/hangx969/local-k8s-gitops
      revision: HEAD
      directories:
      - path: apps/base/*
  template:
    metadata:
      name: '{{path.basename}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/hangx969/local-k8s-gitops
        targetRevision: HEAD
        path: '{{path}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{path.basename}}'
```

### 3. Git Files Generator
基于 Git 仓库中的文件内容生成 Applications

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: apps-from-files
  namespace: argocd
spec:
  generators:
  - git:
      repoURL: https://github.com/hangx969/local-k8s-gitops
      revision: HEAD
      files:
      - path: "apps/*/config.json"
  template:
    metadata:
      name: '{{name}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/hangx969/local-k8s-gitops
        targetRevision: HEAD
        path: '{{path}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{namespace}}'
```

### 4. Cluster Generator
基于注册的集群生成 Applications

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: multi-cluster-app
  namespace: argocd
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          environment: production
  template:
    metadata:
      name: 'myapp-{{name}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/hangx969/local-k8s-gitops
        targetRevision: HEAD
        path: apps/base/myapp
      destination:
        server: '{{server}}'
        namespace: myapp
```

## 使用建议

1. **选择合适的生成器**
   - List: 固定的应用列表
   - Git Directory: 根据目录结构自动发现应用
   - Git Files: 需要更复杂的配置参数化
   - Cluster: 多集群部署

2. **命名规范**
   - 使用清晰的命名模式
   - 避免名称冲突

3. **自动同步**
   - 根据需要配置自动同步策略
   - 考虑使用 syncPolicy.automated

## 最佳实践

- 使用 Git Directory Generator 实现自动发现新应用
- 结合 AppProject 进行权限控制
- 为不同环境使用不同的 ApplicationSet
- 使用模板参数减少重复配置
