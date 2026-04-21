# QA Dashboard

- page: Fortune/Analysis/BaziAnalysis
- gateMode: advisory
- readinessScore: 94
- scoreBreakdown: base 100, -6 (syncBaziAnalysisToBackend pending)
- assumptions:
  - 当前未接入快照框架，只做 ViewModel 状态测试与离线结果确定性验证。

## Coverage
- scenarios: ideal, loading, empty, error
- transactionStepsCovered: step-1, step-2, step-3, step-4

## Matrix
- `ideal`: 有命主档案时刷新成功并展示四柱与五行
- `empty`: 缺少档案时进入保守录入态
- `error`: 服务失败时展示错误提示
- `navigation`: 点击底部 tab 可路由离开当前页面
- `deterministic`: 同一命主档案重复测算得到相同离线结果
- `input-validation`: 非法日期、未知时辰、未知性别与未知历法会在本地直接拦截
- `entitlement`: 普通用户成功测算后扣减 1 灵玉；VIP 规则由权益服务统一兜底

## Skipped
- item: 结果卡像素级快照
  reason: 低置信度区域仍包含保守降级

## Warnings
- type: pending-sync
  target: syncBaziAnalysisToBackend
  action: 若后续接入真实接口，需要重新校验四柱映射、五行比例与文案口径
