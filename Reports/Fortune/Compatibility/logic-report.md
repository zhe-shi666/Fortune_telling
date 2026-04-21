# Logic Report

- page: Fortune/Compatibility/CompatibilityReading
- gateMode: advisory
- assumptions:
  - 合婚推演当前由 `LocalCompatibilityReadingService` 调用 `FortuneAlgorithmEngine.analyzeCompatibility(...)` 完成四柱、喜忌、夫妻宫关系、地支互动与格局互动分析，再映射到本地文案模板。
  - 地支互动已覆盖同柱 `六合 / 相冲 / 相害 / 相刑 / 自刑`，并额外识别双方命局合看的 `寅巳申 / 丑未戌` 三刑链式压力。
  - 若本地存在命主档案，则其默认占用一方输入槽位；另一方使用保守样例值。
  - 契合度分值已拆成 `scoreBreakdown` 结构，用于解释主要加分项与扣分项；当前仍属于离线娱乐参考，不代表专业婚配结论。
  - `合婚推演` 当前必须在双方出生日期与出生时辰都完整时才允许触发；普通用户每次推演消耗 1 灵玉，VIP 不消耗。

## Critical Stubs
- name: syncCompatibilityReadingToBackend
  criticality: medium
  blockingRelease: false
  reason: 真实合婚规则与服务端契合度计算尚未锁定，当前只提供本地离线结果与模板文案收束

## Transaction Steps
- id: step-1
  name: load-profile
  criticality: medium
  rollbackRequired: false
- id: step-2
  name: validate-both-parties
  criticality: high
  rollbackRequired: false
- id: step-3
  name: run-compatibility-analysis
  criticality: high
  rollbackRequired: false
- id: step-4
  name: blend-analysis-with-copy-template
  criticality: medium
  rollbackRequired: false
- id: step-5
  name: summarize-score-breakdown
  criticality: medium
  rollbackRequired: false

## Failure Injection Points
- stepId: step-2
  target: validate-both-parties
  suggestedFailure: 缺少任意一方日期，验证页面给出补录提示
- stepId: step-3
  target: run-compatibility-analysis
  suggestedFailure: 传入不支持的历法、异常日期或命盘相害/相刑/自刑/三刑链式组合，验证页面返回明确可读结果或错误
- stepId: step-3
  target: run-compatibility-analysis
  suggestedFailure: 在普通用户灵玉不足时触发 `FortuneEntitlementError.insufficientJade(.compatibility)`，验证页面不进入 loading，只展示权益提示
- stepId: step-4
  target: blend-analysis-with-copy-template
  suggestedFailure: 模板缺失时验证页面仍能回落到基础四段摘要
- stepId: step-5
  target: summarize-score-breakdown
  suggestedFailure: 分值构成缺失时验证页面仍能输出基础命盘细节与提醒语
