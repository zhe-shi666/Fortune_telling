# Logic Report

- page: Profile/MasterProfile/ProfileEditor
- gateMode: advisory
- assumptions:
  - 档案写入当前默认由 `SwiftDataProfileStore` 持久化到设备本地，未接入多端同步。
  - 保存成功后的回流刷新由 `AppCoordinator` 统一触发，不在页面里直接刷新其他页面状态。
  - 保存成功后页面会短暂展示“今日、八字、合婚与取名会按新档案刷新”的稳定反馈，再自动回到上一页。

## Critical Stubs
- name: syncProfileRecordToBackend
  criticality: medium
  blockingRelease: false
  reason: 当前只做本地持久化，未接入账号体系或远端同步

## Transaction Steps
- id: step-1
  name: load-existing-profile
  criticality: medium
  rollbackRequired: false
- id: step-2
  name: validate-birth-date
  criticality: high
  rollbackRequired: false
- id: step-3
  name: save-profile
  criticality: high
  rollbackRequired: false
- id: step-4
  name: refresh-dependent-pages
  criticality: medium
  rollbackRequired: false

## Failure Injection Points
- stepId: step-2
  target: validate-birth-date
  suggestedFailure: 输入非 `YYYY-MM-DD`，验证页面进入错误提示态
- stepId: step-3
  target: save-profile
  suggestedFailure: 让 store 抛出编码或写入错误，验证页面保留原表单并提示失败
