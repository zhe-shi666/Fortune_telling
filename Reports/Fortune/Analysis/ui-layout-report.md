# UI Layout Report

- page: Fortune/Analysis/BaziAnalysis
- contract: FortuneTelling/Contracts/Fortune/Analysis/BaziAnalysisContract.swift
- scenarios: ideal, loading, empty, error
- assumptions:
  - UI 结构来自 Pencil MCP 设计树 `Screen/Analysis (MKD5u)`。
  - 设计中的四个输入弹窗当前降级为 `Menu` 选择，不保留绝对定位浮层。
  - 系统状态栏与设备展示容器已剥离。
  - 空态与错态未在 Pencil 中完整定义，按保守卡片降级。

## Regions
- id: hero-copy
  confidence: 0.93
  complexAdaptation: false
  fallback: 无，按标题与说明直接实现
- id: input-popups
  confidence: 0.61
  complexAdaptation: true
  fallback: 使用表单内菜单，避免伪造悬浮弹窗交互
- id: result-grid
  confidence: 0.91
  complexAdaptation: false
  fallback: 四柱以 2x2 网格复现
- id: loading-empty-error
  confidence: 0.46
  complexAdaptation: false
  fallback: 使用共享 notice 与简化结果卡

## Reuse
- reused: FortuneTelling/Shared/DesignSystem/FortuneFeatureSupport.swift
- reused: FortuneTelling/Services/Fortune/Profile/ProfileStore.swift
- reused: FortuneTelling/Contracts/Fortune/Analysis/BaziAnalysisContract.swift
