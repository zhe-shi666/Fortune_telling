# Logic Report

- page: Fortune/LocalData/Foundation
- gateMode: advisory
- assumptions:
  - 本轮“本地数据库版”优先按 `SwiftData` 落地，数据库实际存放在应用沙盒容器中，不开放用户自定义路径。
  - 旧版本已存在的 `UserDefaults` 档案、灵玉与收藏数据会在首次读取时保守迁移到本地数据库。
  - 本地知识库只提供娱乐参考/辅助参考所需的离线规则与文案模板，不代表真实后端或专业命理结论。

## Critical Stubs
- name: remoteKnowledgeSync
  criticality: high
  blockingRelease: false
  reason: 当前知识库仍为本地静态种子，若进入商业化内容运营阶段仍需后端下发、审核与版本控制
- name: transactionAuditTrail
  criticality: medium
  blockingRelease: false
  reason: 灵玉扣减目前只做本地持久化，不包含跨设备同步、服务端账本或审计流水

## Transaction Steps
- id: step-1
  name: prepare-local-store
  criticality: high
  rollbackRequired: false
- id: step-2
  name: seed-local-knowledge
  criticality: high
  rollbackRequired: true
- id: step-3
  name: migrate-legacy-userdefaults
  criticality: high
  rollbackRequired: true
- id: step-4
  name: expose-repository-contracts
  criticality: high
  rollbackRequired: false
- id: step-5
  name: generate-fortune-results-from-local-knowledge
  criticality: medium
  rollbackRequired: false

## Failure Injection Points
- stepId: step-1
  target: prepare-local-store
  suggestedFailure: 模拟本地容器创建失败，验证仓储层是否退回保守错误而不是让页面崩溃
- stepId: step-2
  target: seed-local-knowledge
  suggestedFailure: 模拟 seed version 升级时写入失败，验证旧知识是否不会被部分覆盖
- stepId: step-3
  target: migrate-legacy-userdefaults
  suggestedFailure: 提供损坏的旧 JSON 数据，验证迁移失败不会阻塞新数据库继续工作
- stepId: step-5
  target: generate-fortune-results-from-local-knowledge
  suggestedFailure: 返回空知识集，验证服务层能否降级为错误态而不是越界崩溃

## Notes

- 当前 feature 复用了既有页面协议，没有新增页面层 contract，因此本轮直接从逻辑实现阶段推进。
- 本地数据库版已经覆盖“数据表建立 -> 数据生成 -> 接口生成 -> 算法”四步，但仍属于离线 MVP，不等价于正式数据后端。
