# UI Layout Report

- page: Profile/MasterProfile/ProfileEditor
- contract: FortuneTelling/Views/Profile/MasterProfile/ProfileEditorFeature.swift
- scenarios: ideal, loading, empty, error
- assumptions:
  - UI 结构来自当前打开的 Pencil MCP 设计树 `Screen/Profile (LnPqO)`。
  - 系统状态栏与设备外框已剥离，只保留业务区块。
  - `State` / `Action` 与主视图当前合并在同一 feature 文件中，未额外拆出 contract 文件。
  - Pencil 未给出显式校验态与错误态，当前按页面生成助手规则降级为 inline notice。

## Regions
- id: header-card
  confidence: 0.96
  complexAdaptation: false
  fallback: 无，按 Pencil 标题卡直接实现
- id: profile-fields
  confidence: 0.93
  complexAdaptation: false
  fallback: 使用文本输入 + Menu 组合近似出生时辰/性别/历法选择
- id: validation-notice
  confidence: 0.54
  complexAdaptation: false
  fallback: 采用共享 `FortuneInlineNotice`，不额外设计错误插画

## Reuse
- reused: FortuneTelling/Shared/DesignSystem/FortuneFeatureSupport.swift
- reused: FortuneTelling/Services/Fortune/Profile/ProfileStore.swift

## Notes

- `保存并用于今日推演` 与 `返回今日` 都保持为单页按钮，不在页面层硬编码回流目标。
