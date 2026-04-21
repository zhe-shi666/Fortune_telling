# QA Dashboard

- page: Fortune/LocalData/Foundation
- gateMode: advisory
- readinessScore: 85
- scoreBreakdown: base 100, -15 (remoteKnowledgeSync critical stub)
- assumptions:
  - 当前工程没有快照测试框架，本轮只补最小 XCTest 行为测试与 QA 计划。
  - 受当前环境沙盒影响，`SwiftData` 宏的命令行 typecheck 与 Xcode 资产编译都存在噪音，因此更依赖代码级自检与 in-memory 测试覆盖。

## Coverage
- scenarios: ideal, loading, empty, error
- transactionStepsCovered: step-1, step-2, step-3, step-4, step-5

## Matrix
- `profile-persistence`: `SwiftDataProfileStore` 能保存并读回命主档案
- `entitlement-consumption`: 灵玉在非 VIP 状态下会扣减，在 VIP 状态下不扣减
- `daily-knowledge`: 今日服务能从本地知识库生成签语、宜忌和节律文案
- `bazi-knowledge`: 八字服务能基于本地五行解释模板生成结果
- `naming-knowledge`: 取名服务能读取本地词库，并遵守输入姓氏
- `compatibility-knowledge`: 合婚服务能基于本地分段模板生成摘要

## Skipped
- item: 真机或模拟器完整集成测试
  reason: 当前环境缺少可用 Simulator runtime，`actool` 编译阶段会报运行时不可用
- item: 真实后端联调
  reason: 本轮目标是离线本地数据库版本，不接真实服务端

## Warnings
- type: environment
  target: xcodebuild asset catalog / simulator runtime
  action: 在有可用 Xcode Simulator 的环境再补一轮完整 build/test
- type: critical-stub
  target: remoteKnowledgeSync
  action: 若后续进入商业化内容运营阶段，需要补远程知识库和版本同步能力
