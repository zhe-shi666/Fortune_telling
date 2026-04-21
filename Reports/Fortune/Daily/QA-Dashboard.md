# QA Dashboard

- page: Fortune/Daily/TodayOverview
- gateMode: advisory
- readinessScore: 95
- scoreBreakdown: base 100, -5 (syncDailyReadingToBackend pending)
- assumptions:
  - 项目当前没有快照测试框架，因此只生成 XCTest 状态测试与 QA 计划说明。
  - 今日结果当前是离线保守推演，因此测试重点放在确定性、个体差异和状态切换，不验证专业命理正确性。

## Coverage
- scenarios: ideal, loading, empty, error
- transactionStepsCovered: step-1, step-2, step-2b, step-3, step-4

## Matrix
- `ideal`: `TodayOverviewViewModel.refresh()` 成功后进入理想态并包含离线节律内容
- `loading`: `refresh()` 期间使用 loading mock state 驱动页面骨架
- `empty`: 档案缺失时进入引导态并暴露前往档案页 CTA
- `invalid-profile-empty`: 档案字段不完整时回退到 `empty` 引导态，而不是继续请求今日结果
- `error`: 服务失败时展示错误卡与重试按钮
- `deterministic`: 同一档案与日期重复请求得到相同离线结果
- `personalized-diff`: 不同档案或不同日期请求时，宜忌与解签内容应产生可见变化
- `oracle-success`: 解签成功时扣减 1 灵玉并展示解签弹层
- `oracle-entitlement-error`: 灵玉不足时只显示权益提示，不打开解签弹层

## Skipped
- item: 快照测试
  reason: 当前工程未引入任何快照测试框架
- item: 真实支付链路测试
  reason: `RechargeCenter` 本轮明确不接真实支付能力

## Warnings
- type: pending-sync
  target: syncDailyReadingToBackend
  action: 若后续接入真实 API，需要校对离线结果与服务端返回之间的替换策略
- type: low-confidence-ui
  target: empty-state / error-state
  action: 后续若 Pencil 补充空态和错态设计，需要同步更新页面和测试断言
