# Logic Report

- page: Fortune/Analysis/BaziAnalysis
- gateMode: advisory
- assumptions:
  - 八字测算结果当前由 `LocalBaziAnalysisService` 基于出生日期、时辰、性别与历法做离线保守推演，不代表真实命理结论。
  - 若存在命主档案，则页面默认使用档案预填，但仍需用户主动点击 `合取测算` 才会发起本次娱乐参考测算。
  - 八字入口当前已统一校验出生日期、时辰、性别与历法四项，任一项不合法都会在本地直接拦截，不再把无效值透传给算法层。
  - `合取测算` 属于权益消耗动作；普通用户每次成功触发请求会消耗 1 灵玉，VIP 不消耗。

## Critical Stubs
- name: syncBaziAnalysisToBackend
  criticality: medium
  blockingRelease: false
  reason: 当前只实现本地离线推演，未来若接真实服务仍需补齐契约映射与结果校验

## Transaction Steps
- id: step-1
  name: load-profile
  criticality: medium
  rollbackRequired: false
- id: step-2
  name: validate-input
  criticality: high
  rollbackRequired: false
- id: step-3
  name: request-analysis
  criticality: high
  rollbackRequired: false
- id: step-4
  name: map-five-elements
  criticality: medium
  rollbackRequired: false

## Failure Injection Points
- stepId: step-2
  target: validate-input
  suggestedFailure: 提供非法日期、未知时辰、未知性别或不支持的历法，验证页面进入错误提示态
- stepId: step-3
  target: request-analysis
  suggestedFailure: 抛出 `BaziAnalysisServiceError.serviceUnavailable`
- stepId: step-3
  target: request-analysis
  suggestedFailure: 在普通用户余额不足时触发 `FortuneEntitlementError.insufficientJade(.bazi)`，验证页面只提示、不进入 loading
