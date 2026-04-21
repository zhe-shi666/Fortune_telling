---
name: 页面生成助手
description: 将 Pencil 设计稿、截图、页面草图或结构化页面描述转换为中小型 iOS/SwiftUI 页面代码。适用于生成或重构 View、页面 Contract、Mock 数据与 ui-layout-report.md，尤其适合需要与逻辑实现助手、测试助手共享 MockScenario、confidence 和适配标记的任务。
---

# 页面生成助手

生成可落地的 SwiftUI 页面代码，并为后续逻辑和测试阶段产出稳定的共享输入。

## 共享协议

在与其他 skill 协同时，统一使用以下字段名。若项目中已有等价结构，先做映射，不要重复发明新名词。

- `MockScenario`：仅使用 `ideal`、`loading`、`empty`、`error` 四个值。
- `confidence`：使用 `0.0 ... 1.0` 浮点数，并严格按阈值驱动降级：
  - `>= 0.85`：按设计正常落地，只保留少量假设
  - `0.60 ... 0.84`：可落地主结构，复杂细节降级
  - `0.40 ... 0.59`：只保留最小骨架与核心动作，`complexAdaptation` 默认 `true`
  - `< 0.40`：只输出语义占位、阻塞项或人工确认点
- `complexAdaptation`：布尔值，表示该区域是否需要额外适配验证。
- `criticality`：仅使用 `high`、`medium`、`low`。
- `gateMode`：仅使用 `advisory`、`blocking`。默认视为 `advisory`。

`ui-layout-report.md` 至少包含以下字段：

```md
# UI Layout Report

- page: Auth/Login
- contract: Contracts/Auth/LoginContract.swift
- scenarios: ideal, loading, empty, error
- assumptions:
  - 未找到 Index.swift，改为扫描同级目录复用现有组件

## Regions
- id: footer
  confidence: 0.35
  complexAdaptation: false
  fallback: AnnotationView

## Reuse
- reused: Components/TextFieldRow.swift
- reused: Actions/Auth/LoginAction.swift
```

## 执行流程

### 1. 先读取现有上下文

优先读取以下内容，再开始生成页面：

- 当前任务直接提供的设计稿、截图、页面草图或结构化描述。
- 当前模块已存在的 `View`、`Contract`、`Mock`、`Action`、`Index.swift`。
- 与目标页面同层或相邻目录中可复用的组件。
- 若存在 `Reports/[Domain]/[Feature]/logic-report.md` 或 `Reports/[Domain]/[Feature]/QA-Dashboard.md`，优先读取以避免与已有逻辑层和测试层结论冲突。

若 `Index.swift` 不存在，不要伪造它；改为扫描同级目录，记录复用判断依据，并在 `ui-layout-report.md` 的 `assumptions` 中写明降级原因。

当输入来自 Pencil MCP、设计稿或截图时，先识别并剥离系统 UI 与设计容器：

- 顶部 `09:41`、电量、信号、Wi-Fi、运营商、刘海、灵动岛等元素，默认视为系统状态栏，不生成业务 UI。
- 底部 `Home Indicator` 或设备手势条，默认视为系统容器，不生成页面元素。
- 整台手机外框、阴影、展示底板，默认视为展示容器，不生成业务代码。
- 这些元素只用于推断安全区、留白和布局边界。
- 只有在设计明确要求自绘状态栏或设备展示效果时，才保留，并在 `ui-layout-report.md` 中标记为装饰性元素。

### 2. 先定页面契约，再写视图

先确定最小页面契约，再开始生成主视图：

- 明确 `State` 中真正驱动 UI 分支的字段。
- 明确 `Action` 中会触发页面状态变化的交互。
- 明确 `MockScenario` 的四个标准场景如何映射到页面状态。

若设计信息不足以支持复杂交互，优先产出最小可编译契约，不要编造不存在的数据流。

若页面生成过程中反向发现 `docs/app.md`、`docs/domain.md` 或 `docs/api.md` 与真实页面需求不一致，先按 `app -> domain -> api -> 当前阶段报告 -> skill` 的顺序回流更新，再继续写页面代码。

若项目从 0 开始或尚无运行入口，不要只生成页面文件；还要一并生成最小可运行装配，让当前页面能被打开做人工审核。

### 3. 生成干净的主视图

默认让主视图保持发布态干净：

- 将低置信度占位逻辑放到独立的 `View+Debug.swift`，或包裹在 `#if DEBUG` 中。
- 不要在发布路径的主 `body` 中直接渲染 debug overlay。
- 对 `confidence` 位于 `0.40 ... 0.59` 的区域，仅生成最小骨架和核心动作，复杂布局细节降级，并在报告里标记 `complexAdaptation: true`。
- 对 `confidence < 0.40` 的区域，仅生成简单、语义明确的占位结构，例如 `AnnotationView` 或注释占位，并在报告里写明原因。

若项目没有 `AnnotationView` 或独立 debug 扩展模式，改用最简单的 `Text("TODO: clarify layout")` 形式放在 `#if DEBUG` 中，并在报告里写清楚采用了降级实现。

### 4. 只为关键分支生成 Mock

只为会切换 UI 分支的字段生成多场景 Mock：

- 优先覆盖 `ideal`、`loading`、`empty`、`error` 四个标准场景。
- 非关键字段使用稳定默认值，不为它们制造额外的 Mock 组合。
- 若项目已有 `PreviewProvider`、工厂方法或样例数据结构，优先复用已有模式。

### 5. 产出共享报告

始终生成 `ui-layout-report.md`，并至少写入：

- 页面路径与关联 Contract 路径。
- 四个标准场景。
- 低置信度区域及其 `confidence`。
- 低置信度区域对应的阈值分段与降级动作。
- `complexAdaptation` 为 `true` 的区域。
- 所有降级实现和关键假设。

### 6. 在输出前做一致性自检

输出前至少检查以下内容：

- View 中引用的字段是否都存在于 `State`。
- 交互事件是否都存在于 `Action`。
- Mock 场景名是否严格使用共享协议中的四个值。
- 报告中的组件标识是否能对应到代码中的区域或文件。

若存在无法修复的不一致，不要继续硬写代码；改为停止生成复杂部分，并在报告中明确列出阻塞项。

## 输出合同

- `Contracts/[Domain]/[Feature]/[Page]Contract.swift`：最小且可编译的页面契约。
- `Views/[Domain]/[Feature]/[Page]View.swift`：发布路径干净的主视图。
- `Views/[Domain]/[Feature]/[Page]View+Debug.swift`：仅在需要时生成的 debug 辅助视图。
- `Mocks/[Domain]/[Feature]/[Page]MockFactory.swift`：只覆盖关键场景的 Mock 工厂。
- `Reports/[Domain]/[Feature]/ui-layout-report.md`：供逻辑实现助手和测试助手消费的共享布局报告。
- 若项目尚无运行入口：同时生成最小 app 入口、根路由或首屏装配代码，使当前页面可以被打开审核。

## 约束与停止条件

- 不要假设项目一定有 `GlobalRegistry`、`AnnotationView`、`Index.swift` 或自定义 DSL；只有在项目里发现它们时才使用。
- 不要为了“完整感”编造复杂导航、网络层或数据层。
- 若设计输入过于模糊，优先交付可编译骨架和完整报告，而不是伪精确 UI。
- 若无法同时满足“可编译”和“贴近设计”，优先保证可编译，并把偏差写入 `ui-layout-report.md`。
