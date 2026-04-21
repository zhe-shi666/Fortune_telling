# Logic Report

- page: Fortune/Daily/TodayOverview
- gateMode: advisory
- assumptions:
  - 今日运势当前默认由 `LocalDailyFortuneService` 基于已保存档案与当天日期做离线保守推演，不宣称为真实命理服务。
  - 今日宜忌与解签当前不再直接套固定文案，而是由“命盘分析信号 + 当日干支 + 本地知识规则”共同收束；同一人同一天保持稳定，不同人或不同日期会变化。
  - 命主档案当前默认由 `SwiftData` 本地仓储提供设备持久化数据；首启无档案或档案字段不完整时进入 `empty` 引导态。
  - 跳转到 `命主页面`、`充值页面`、其他 tab 页面由 `AppCoordinator` 统一处理，不把导航目标硬编码到 View。
  - 解签动作会先校验灵玉或 VIP 权益；普通用户成功解签后扣减 1 灵玉，灵玉不足时只提示，不打开弹层。

## Critical Stubs
- name: syncDailyReadingToBackend
  criticality: medium
  blockingRelease: false
  reason: 当前只实现本地离线推演，未来若要接入真实服务仍需补齐接口映射与结果校验

## Transaction Steps
- id: step-1
  name: load-profile
  criticality: high
  rollbackRequired: false
- id: step-2
  name: request-daily-reading
  criticality: high
  rollbackRequired: false
- id: step-2b
  name: personalize-guidance-and-oracle
  criticality: high
  rollbackRequired: false
- id: step-3
  name: map-view-state
  criticality: medium
  rollbackRequired: false
- id: step-4
  name: present-oracle-overlay
  criticality: low
  rollbackRequired: false

## Failure Injection Points
- stepId: step-1
  target: load-profile
  suggestedFailure: 返回 `nil` 或不完整档案，验证页面进入 `empty` 引导态
- stepId: step-2
  target: request-daily-reading
  suggestedFailure: 抛出 `DailyFortuneServiceError.serviceUnavailable`
- stepId: step-2b
  target: personalize-guidance-and-oracle
  suggestedFailure: 将个性化选择退回固定文案，验证测试能发现“同人同日稳定但异人异日不变化”的回归问题
- stepId: step-4
  target: present-oracle-overlay
  suggestedFailure: 灵玉不足时验证页面只展示权益提示，不打开解签弹层

## Notes

- 高影响动作包括“读取档案”、“获取今日结果”和“解签权益校验”；其余进入页面与 tab 跳转按低影响导航处理。
- 当前未引入统一日志器、事务包装器或容器框架，保持协议注入与最小 coordinator 即可。
