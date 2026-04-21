# QA Dashboard

- page: Profile/MasterProfile/ProfileEditor
- gateMode: advisory
- readinessScore: 94
- scoreBreakdown: base 100, -6 (syncProfileRecordToBackend pending)
- assumptions:
  - 当前项目没有快照测试框架，因此只覆盖 ViewModel 行为测试、表单校验与本地持久化验证。

## Coverage
- scenarios: ideal, loading, empty, error
- transactionStepsCovered: step-1, step-2, step-3, step-4

## Matrix
- `ideal`: 已有档案时刷新进入理想态并展示保存值
- `error`: 无效日期保存时展示错误提示
- `ideal/save`: 有效输入保存后写入 store 并触发返回
- `success-feedback`: 保存成功后先展示刷新说明，再由协调器负责回流
- `persist`: 本地持久化 store 可在新实例中读回已保存档案

## Skipped
- item: 页面快照测试
  reason: 工程未引入快照测试框架

## Warnings
- type: pending-sync
  target: syncProfileRecordToBackend
  action: 若未来引入账号体系，需要补齐远端同步、冲突处理与迁移策略
