# ArgoCD 配置

本目录用于存放 ArgoCD 的核心配置资源。

## 目录结构

```
argocd/
├── projects/              # AppProject 定义
│   ├── project-1.yaml
│   ├── project-2.yaml
│   └── README.md
├── applicationsets/       # ApplicationSet 定义
│   ├── appset-1.yaml
│   ├── appset-2.yaml
│   └── README.md
└── README.md
```

## 组件说明

### AppProjects (projects/)
AppProject 用于对 Applications 进行逻辑分组和权限管理。

### ApplicationSets (applicationsets/)
ApplicationSet 用于自动化生成和管理多个 ArgoCD Applications。

## 使用说明

1. **应用 AppProject**
   ```bash
   kubectl apply -f argocd/projects/
   ```

2. **应用 ApplicationSet**
   ```bash
   kubectl apply -f argocd/applicationsets/
   ```

## 注意事项

- AppProject 需要在 Applications 之前创建
- ApplicationSet 会自动创建和管理 Applications
- 确保资源配置符合集群的权限策略
