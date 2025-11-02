# ArgoCD AppProjects

本目录存放 ArgoCD AppProject 资源定义。

## 什么是 AppProject？

AppProject 是 ArgoCD 中用于对 Applications 进行分组和权限控制的资源。它可以：

- 限制应用可以部署的目标集群和命名空间
- 限制应用可以使用的源仓库
- 定义应用可以部署的资源类型
- 配置同步窗口和策略

## 示例

创建一个基础的 AppProject：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: my-project
  namespace: argocd
spec:
  description: My Application Project
  
  # 允许的源仓库
  sourceRepos:
    - 'https://github.com/hangx969/local-k8s-gitops'
    - 'https://charts.bitnami.com/bitnami'
  
  # 允许的目标集群和命名空间
  destinations:
    - namespace: '*'
      server: 'https://kubernetes.default.svc'
  
  # 允许部署的资源类型
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
  
  namespaceResourceWhitelist:
    - group: '*'
      kind: '*'
```

## 最佳实践

1. **按团队或项目组织**
   - 为不同的团队或项目创建独立的 AppProject
   - 使用有意义的命名

2. **最小权限原则**
   - 只授予必要的仓库访问权限
   - 限制可部署的命名空间
   - 限制可部署的资源类型

3. **使用 RBAC**
   - 结合 ArgoCD RBAC 策略使用
   - 控制谁可以管理项目中的应用

## 常用场景

- **开发/测试/生产环境隔离**：为每个环境创建独立的 Project
- **多租户管理**：为每个租户创建独立的 Project
- **权限分级**：根据权限级别创建不同的 Project
