# UI Layout Report

- page: Fortune/Naming/NamingWorkshop
- contract: FortuneTelling/Contracts/Fortune/Naming/NamingWorkshopContract.swift
- scenarios: ideal, loading, empty, error
- assumptions:
  - UI 结构来自 Pencil MCP 设计树 `Screen/Naming (4GjJC)`。
  - 设计中的收藏清单面板位于画布右侧，当前降级为遮罩弹层，不实现侧滑轨迹动画。
  - 设备状态栏与展示容器已剥离。
  - 空态与错态未给出独立设计，采用统一 notice + 空卡降级。
  - 性别与出生时辰选择器未在原设计稿中单独强调，本轮沿用现有深色下拉样式补入输入卡，以满足命理算法精度要求。

## Regions
- id: favorites-chip
  confidence: 0.92
  complexAdaptation: false
  fallback: 无，保持顶部胶囊按钮
- id: recommendation-cards
  confidence: 0.9
  complexAdaptation: false
  fallback: 名字卡片维持单列竖向结构
- id: favorites-panel
  confidence: 0.66
  complexAdaptation: true
  fallback: 使用 modal overlay 替代右侧抽屉
- id: birth-hour-input
  confidence: 0.71
  complexAdaptation: false
  fallback: 复用八字页的深色下拉字段样式
- id: gender-input
  confidence: 0.72
  complexAdaptation: false
  fallback: 复用八字页的深色下拉字段样式
- id: empty-error-states
  confidence: 0.43
  complexAdaptation: false
  fallback: 采用保守文案卡片，不强推复杂插画

## Reuse
- reused: FortuneTelling/Shared/DesignSystem/FortuneFeatureSupport.swift
- reused: FortuneTelling/Contracts/Fortune/Naming/NamingWorkshopContract.swift
