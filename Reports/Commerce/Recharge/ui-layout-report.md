# UI Layout Report

- page: Commerce/Recharge/RechargeCenter
- contract: FortuneTelling/Contracts/Commerce/Recharge/RechargeCenterContract.swift
- scenarios: ideal, loading, empty, error
- assumptions:
  - UI 结构来自 Pencil MCP 设计树 `Screen/Recharge (J7EhV)`。
  - 真实支付、订单回调与交易状态均不在本轮实现范围内。
  - 设计里的返回按钮为绝对定位，当前降级为主内容区下方的常规次按钮。

## Regions
- id: balance-card
  confidence: 0.95
  complexAdaptation: false
  fallback: 无，按渐变余额卡直接实现
- id: plans-list
  confidence: 0.92
  complexAdaptation: false
  fallback: 选中态通过描边与深色底区分
- id: payment-method-list
  confidence: 0.9
  complexAdaptation: false
  fallback: 用圆点选中态复现设计
- id: loading-error-states
  confidence: 0.45
  complexAdaptation: false
  fallback: 使用 inline notice，不扩展复杂支付失败页

## Reuse
- reused: FortuneTelling/Shared/DesignSystem/FortuneFeatureSupport.swift
- reused: FortuneTelling/Contracts/Commerce/Recharge/RechargeCenterContract.swift
