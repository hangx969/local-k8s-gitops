# Applications

本目录用于存放应用的配置文件，采用 Kustomize 或纯 YAML 的方式组织。

## 目录结构

```
apps/
├── base/                 # 基础配置（环境无关）
│   ├── app-1/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   └── app-2/
│       └── ...
├── overlays/             # 环境特定配置
│   ├── dev/              # 开发环境
│   │   ├── app-1/
│   │   │   ├── kustomization.yaml
│   │   │   └── values-override.yaml
│   │   └── app-2/
│   │       └── ...
│   ├── staging/          # 预发布环境
│   │   └── ...
│   └── prod/             # 生产环境
│       └── ...
└── README.md
```

## 使用场景

本目录适合以下场景：

1. **使用第三方 Helm Charts**
   - base/ 目录存放 values.yaml
   - overlays/ 存放环境特定的 values 覆盖

2. **使用 Kustomize**
   - base/ 目录存放基础 manifests
   - overlays/ 存放环境特定的补丁和配置

3. **纯 YAML 部署**
   - 直接存放 Kubernetes YAML 文件

## 使用说明

### Kustomize 方式

1. **查看渲染后的配置**
   ```bash
   kubectl kustomize apps/overlays/dev/app-1
   ```

2. **应用配置**
   ```bash
   kubectl apply -k apps/overlays/dev/app-1
   ```

### Helm Values 方式

将 values 文件与 ArgoCD Application 配合使用：
```yaml
spec:
  source:
    helm:
      valueFiles:
        - ../../apps/base/app-1/values.yaml
        - ../../apps/overlays/prod/app-1/values-override.yaml
```

## 最佳实践

- 将环境无关的配置放在 base/
- 环境特定的配置放在对应的 overlays/
- 使用有意义的应用名称
- 保持配置文件的简洁和可读性
