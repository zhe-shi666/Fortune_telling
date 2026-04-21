# QA Dashboard

- page: Fortune/Compatibility/CompatibilityReading
- gateMode: advisory
- readinessScore: 96
- scoreBreakdown: base 100, -4 (syncCompatibilityReadingToBackend pending)
- assumptions:
  - 当前演示环境无法验证真实婚配规则，仅验证状态机、路由行为、离线结果确定性与结构化分值解释。
  - 当前离线结果已切到统一算法底座，但对外仍只表述为娱乐参考或辅助参考。

## Coverage
- scenarios: ideal, loading, empty, error
- transactionStepsCovered: step-1, step-2, step-3, step-4, step-5

## Matrix
- `ideal`: 有命主档案时刷新成功并展示离线契合度
- `empty`: 无命主档案时停留在等待补录态
- `error`: 服务失败时展示错误提示
- `navigation`: 点击底部 tab 可路由离开当前页面
- `required-inputs`: 双方的出生日期与出生时辰未补齐前，页面应保持按钮禁用与说明文案
- `deterministic`: 相同双方输入重复推演得到相同结果
- `algorithm-copy-blend`: 结果首行包含契合度判断与夫妻宫描述
- `score-breakdown`: 结果末段包含主要加分项与主要留意项
- `harm-pair-sample`: 覆盖夫妻宫 `相害` 的离线样例，确认关系标签、扣分项与提示一致
- `punishment-pair-sample`: 覆盖夫妻宫 `相刑` 的离线样例，确认关系标签、扣分项与提示一致
- `self-punishment-sample`: 覆盖夫妻宫 `自刑` 的离线样例，确认同支组合也能落到 `相刑` 规则
- `cross-chart-triple-punishment-sample`: 覆盖双方命局合看形成 `三刑` 的离线样例，确认链式压力提示、关系标签与扣分项一致
- `entitlement`: 普通用户成功推演后扣减 1 灵玉；VIP 规则由权益服务统一兜底

## Skipped
- item: 真实婚配规则校验
  reason: 当前只接入离线保守推演结果

## Warnings
- type: pending-sync
  target: syncCompatibilityReadingToBackend
  action: 接入真实合婚接口前，不要把当前离线分值与相害/相刑/自刑/三刑提示视为专业婚配结论
