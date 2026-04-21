# UI Layout Report

- page: Fortune/Compatibility/CompatibilityReading
- contract: FortuneTelling/Contracts/Fortune/Compatibility/CompatibilityReadingContract.swift
- scenarios: ideal, loading, empty, error
- assumptions:
  - UI 结构来自 Pencil MCP 设计树 `Screen/Compatibility (YbiNK)`。
  - 当前默认以命主档案作为一方输入，另一方使用保守样例值完成演示闭环。
  - 状态栏、设备外框与手势条已剥离。
  - 空态与错态按共享 notice 保守降级。

## Regions
- id: hero-card
  confidence: 0.94
  complexAdaptation: false
  fallback: 无，按设计稿渐变卡片实现
- id: dual-profile-forms
  confidence: 0.9
  complexAdaptation: false
  fallback: 用两个并列输入控件卡片近似设计
- id: score-bar
  confidence: 0.88
  complexAdaptation: false
  fallback: 使用胶囊进度条呈现契合度
- id: empty-error-states
  confidence: 0.47
  complexAdaptation: false
  fallback: 用 inline notice 代替复杂失败视图

## Reuse
- reused: FortuneTelling/Shared/DesignSystem/FortuneFeatureSupport.swift
- reused: FortuneTelling/Contracts/Fortune/Compatibility/CompatibilityReadingContract.swift
