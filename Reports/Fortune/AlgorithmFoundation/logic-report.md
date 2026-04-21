# Logic Report

- page: Fortune/AlgorithmFoundation/Core
- gateMode: advisory
- assumptions:
  - 当前历法底座为项目内实现的 `FortuneAlgorithmEngine`，优先解决真太阳时、四柱、五行、十神与流日主线，不依赖外部包。
  - `TodayOverview`、`BaziAnalysis`、`CompatibilityReading` 与 `NamingWorkshop` 已统一接到同一算法底座；四类结果当前统一走“实时算法结果 + 本地知识模板映射层”。
  - `NamingWorkshop` 当前页面已显式采集出生日期与出生时辰，取名算法不再依赖午时回落近似方案。
  - 当前公历、普通农历与农历闰月输入都已接到同一历法换算链路；后续重点转为黄金样例校对，而不是继续补输入表达。
  - `SwiftData` 本地仓储现已显式落到 `Application Support/FortuneLocalStore.store`，避免真实运行时再依赖 CoreData 的恢复性建库。

## Critical Stubs
- none

## Transaction Steps
- id: step-1
  name: normalize-input
  criticality: high
  rollbackRequired: false
- id: step-2
  name: resolve-true-solar-time
  criticality: high
  rollbackRequired: false
- id: step-3
  name: derive-four-pillars
  criticality: high
  rollbackRequired: false
- id: step-4
  name: score-five-elements-and-ten-gods
  criticality: high
  rollbackRequired: false
- id: step-5
  name: capture-structured-trace
  criticality: medium
  rollbackRequired: false
- id: step-6
  name: map-analysis-to-feature-payloads
  criticality: medium
  rollbackRequired: false
- id: step-7
  name: blend-analysis-with-local-copy
  criticality: medium
  rollbackRequired: false

## Failure Injection Points
- stepId: step-1
  target: normalize-input
  suggestedFailure: 输入非法日期或不支持的历法，验证算法层返回明确错误
- stepId: step-2
  target: resolve-true-solar-time
  suggestedFailure: 传入异常经度或缺省经度，验证真太阳时仍能保守降级
- stepId: step-3
  target: derive-four-pillars
  suggestedFailure: 节气边界日期或农历闰月输入附近，验证年柱/月柱切换不会越界崩溃
- stepId: step-5
  target: capture-structured-trace
  suggestedFailure: 结构化评分缺失或映射键错误时，验证服务层仍能回落到最小可读解释
- stepId: step-6
  target: map-analysis-to-feature-payloads
  suggestedFailure: 分析结果缺失某项五行分值时，验证页面仍能显示可解释错误
- stepId: step-7
  target: blend-analysis-with-local-copy
  suggestedFailure: 合婚或取名模板缺失时，验证页面仍能回落到保守且可读的结果文本

## Notes

- 这轮的重点是把“模板型 seed 逻辑”替换为“可解释的命理结构化分析”，并统一四个主要命理功能的评分口径。
- 已补齐今日信号命中、八字五行/格局候选、取名候选得分拆解，以及今日/八字/合婚/取名四条映射层。
- 已补黄金样例边界断言：立春前后年柱切换、真太阳时经度修正可导致时柱切换、取名得分拆解闭合。
- 公历、普通农历与农历闰月都已接通到公历换算；当前黄金样例已按现行算法输出重新校对并通过执行态测试。
- 真太阳时与节气换算当前为项目内近似实现；若后续引入 `sxtwl` 或同等级底座，需要做一轮黄金样例回归。
