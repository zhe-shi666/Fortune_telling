# Logic Report

- page: Fortune/Naming/NamingWorkshop
- gateMode: advisory
- assumptions:
  - 名字推荐当前由 `LocalNamingRecommendationService` 调用 `FortuneAlgorithmEngine.recommendNames(...)` 完成喜用神导向排序，再映射为页面候选卡片。
  - 姓氏输入当前收敛为可选的 `1` 到 `2` 个中文字符；页面侧会做约束，服务侧会做兜底校验。
  - 性别已改为取名页显式输入，并参与候选风格排序；当前允许中性名字继续出现，但会压低明显不匹配的风格候选。
  - 收藏清单当前由 `SwiftDataNamingFavoritesStore` 持久化到设备本地，不做跨设备同步。
  - 页面默认只预填档案中的性别、日期与时辰，不自动展示推荐；用户每次点击生成按钮追加 2 个，同输入继续追加，更换姓氏、性别、日期或时辰时清空当前推荐。
  - `生成雅名` 属于权益消耗动作；普通用户每点击一次都会消耗 1 灵玉，即使是同日期继续追加也遵循同一规则，VIP 不消耗。
  - 取名分值已从“顶格上限型”改为分布式评分，综合喜用神、辅助五行、音律、语义和候选顺位计算，不再默认撞到 99 分。

## Critical Stubs
- name: syncNameRecommendationsToBackend
  criticality: medium
  blockingRelease: false
  reason: 真实取名接口与评分规则尚未确定，当前只提供本地离线候选结果
- name: persistFavoriteNames
  criticality: medium
  blockingRelease: false
  reason: 收藏已支持跨启动保留，但仍缺少账号同步与迁移能力

## Transaction Steps
- id: step-1
  name: load-profile
  criticality: medium
  rollbackRequired: false
- id: step-2
  name: validate-required-inputs
  criticality: high
  rollbackRequired: false
- id: step-3
  name: build-naming-engine-input
  criticality: high
  rollbackRequired: false
- id: step-4
  name: run-naming-analysis-and-map-candidates
  criticality: high
  rollbackRequired: false
- id: step-5
  name: reveal-next-two-candidates
  criticality: high
  rollbackRequired: false
- id: step-6
  name: toggle-favorite-local
  criticality: high
  rollbackRequired: false

## Failure Injection Points
- stepId: step-2
  target: validate-required-inputs
  suggestedFailure: 缺少性别、出生日期、出生时辰或输入非法姓氏时，验证页面保持禁用或给出克制提示
- stepId: step-3
  target: build-naming-engine-input
  suggestedFailure: 输入非支持时辰值或非法性别值时，验证逻辑返回明确错误而不是静默回落
- stepId: step-4
  target: run-naming-analysis-and-map-candidates
  suggestedFailure: 模板词库缺失或性别约束未参与排序时，验证页面返回明确错误或暴露排序异常
- stepId: step-5
  target: reveal-next-two-candidates
  suggestedFailure: 更换出生日期、性别或姓氏后未清空旧推荐，需验证状态立即回到空态
- stepId: step-4
  target: run-naming-analysis-and-map-candidates
  suggestedFailure: 在普通用户灵玉不足时触发 `FortuneEntitlementError.insufficientJade(.naming)`，验证页面停留在当前状态并给出克制提示
