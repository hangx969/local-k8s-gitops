# Helm Charts

本目录用于存放自定义的 Helm Charts，可以包括：

## 目录结构

```
charts/
├── app-name-1/           # 应用1的Helm Chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── templates/
│   └── ...
├── app-name-2/           # 应用2的Helm Chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── templates/
│   └── ...
└── README.md
```

## 使用说明

1. **创建新的 Helm Chart**
   ```bash
   cd charts
   helm create <app-name>
   ```

2. **本地测试 Chart**
   ```bash
   helm template <app-name> ./charts/<app-name>
   helm lint ./charts/<app-name>
   ```

3. **打包 Chart（可选）**
   ```bash
   helm package ./charts/<app-name>
   ```

## Chart 组织方式

- 每个应用一个独立的目录
- Chart 名称应该清晰明确
- 包含完整的 Chart.yaml 元数据
- 提供合理的默认 values.yaml
- 模板文件放在 templates/ 目录下

## 注意事项

- 遵循 [Helm Chart 最佳实践](https://helm.sh/docs/chart_best_practices/)
- 为重要的配置项添加注释
- 保持 Chart 的可复用性和可配置性
