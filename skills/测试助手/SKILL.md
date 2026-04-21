---
name: 测试助手
description: 为中小型 iOS/SwiftUI 项目生成 XCTest、异步状态验证、快照回归策略、事务故障注入计划与 QA-Dashboard.md。适用于消费页面生成助手和逻辑实现助手的共享报告，尤其适合根据 MockScenario、confidence、criticality 和 transactionSteps 生成分层测试。
---

# 测试助手

根据页面和逻辑阶段的共享产物，生成能落地、能降级、不会误伤早期迭代节奏的测试方案与测试代码。

## 共享协议

与其他两个 skill 协同时，统一消费以下字段：

- `MockScenario`：仅使用 `ideal`、`loading`、`empty`、`error`。
- `confidence`：使用 `0.0 ... 1.0` 浮点数，并严格按阈值驱动测试强度：
  - `>= 0.85`：可做常规行为覆盖与稳定快照
  - `0.60 ... 0.84`：主链路正常测试，快照或视觉断言降一档
  - `0.40 ... 0.59`：以结构、状态和行为断言为主，不做高承诺视觉断言
  - `< 0.40`：降级为测试计划、人工检查清单或最小占位断言
- `complexAdaptation`：布尔值，来自 `ui-layout-report.md`，表示该区域需要额外适配验证。
- `criticality`：仅使用 `high`、`medium`、`low`。
- `gateMode`：仅使用 `advisory`、`blocking`。未明确指定时默认 `advisory`。
- `transactionSteps`：有序数组，每一项至少包含 `id`、`name`、`criticality`、`rollbackRequired`。

`QA-Dashboard.md` 至少包含以下字段：

```md
# QA Dashboard

- page: Auth/Login
- gateMode: advisory
- readinessScore: 65
- scoreBreakdown: base 100, -15 (submitLogin critical stub), -20 (blocking gap uncovered)
- assumptions:
  - 未检测到快照测试框架，跳过快照代码生成，改为输出测试计划

## Coverage
- scenarios: ideal, loading, empty, error
- transactionStepsCovered: step-1, step-2

## Skipped
- item: 快照测试
  reason: 项目未引入快照框架

## Warnings
- type: critical-stub
  target: submitLogin
  action: release 前补齐真实实现
```

## 执行流程

### 1. 先识别项目已有测试基础设施

优先读取以下内容：

- 现有 `XCTestCase`、测试工具函数、异步等待封装。
- 当前项目是否已有快照测试框架。
- 当前项目是否已有 `SwiftData` in-memory 测试基建、Mock Service 或故障注入入口。
- `Reports/[Domain]/[Feature]/ui-layout-report.md` 与 `Reports/[Domain]/[Feature]/logic-report.md`。

若某类测试基础设施不存在，不要硬造一整套新框架；改为生成最小测试骨架或测试计划，并在 `QA-Dashboard.md` 中记录降级原因。

若测试阶段反向发现产品范围、业务规则、接口契约或交接判断已变化，先按 `app -> domain -> api -> 当前阶段报告 -> skill` 的顺序回流更新，再继续出测试代码或测试计划。

### 2. 先按共享协议建立测试矩阵

始终先根据共享产物建立最小测试矩阵：

- 对 `MockScenario` 的四个标准场景做覆盖规划。
- 对 `criticality: high` 的动作优先安排行为测试。
- 对 `transactionSteps` 安排失败注入点。
- 对 `confidence < 0.85` 或 `complexAdaptation: true` 的区域降低快照预期强度。
- 对 `confidence < 0.60` 的区域默认不承诺高精度快照，以结构与状态断言为主。

### 3. 生成异步状态测试

若项目已有异步测试辅助函数，优先复用；否则生成最简单的等待工具。

- 至少覆盖 `submit -> loading -> success/error` 这类主链路。
- 不要要求所有状态都做复杂时序断言；仅覆盖会影响用户可见行为的状态切换。
- 若页面没有异步状态流，退化为同步状态断言，不要强造 `Published` 或 Combine 依赖。

### 4. 按门禁模式处理 Stub

对高影响 Stub 的处理必须受 `gateMode` 控制：

- `gateMode: advisory`：默认只在 `QA-Dashboard.md` 中记录警告，或使用 `XCTExpectFailure` 表达已知缺口。
- `gateMode: blocking`：仅在明确要求发布门禁或项目已有同类规则时，才生成 `XCTFail` 级阻断测试。

不要把早期迭代默认变成红灯流水线。

### 5. 按条件生成快照测试

只有在项目已经使用快照测试框架时，才生成快照代码。

- `ideal` 场景优先全页面快照。
- `empty`、`error`、低置信度区域优先组件级快照或计划项。
- 对 `confidence` 位于 `0.60 ... 0.84` 的区域，放宽像素容差或改成组件级快照。
- 对 `confidence < 0.60` 的区域，直接降级为人工检查清单、测试计划或最小行为断言。

若项目没有快照框架，改为在 `QA-Dashboard.md` 中输出建议覆盖列表，不要凭空引入第三方库约定。

### 6. 按条件生成事务故障注入测试

只有在 `logic-report.md` 提供了 `transactionSteps`，且项目具备 mock/in-memory 基础设施时，才生成事务失败注入测试。

- 优先消费 `Reports/[Domain]/[Feature]/logic-report.md` 中的 `## Failure Injection Points` 作为失败注入起点；若该章节缺失，再结合 `transactionSteps` 自行推断。
- 每个高影响步骤都可以有一个失败注入点。
- 若无法安全验证回滚，只输出测试计划和断言建议，不编造数据库 API。
- 若逻辑层只给出了步骤表而没有真实事务封装，也可以先生成 plan-first 的测试骨架。

### 7. 产出 QA-Dashboard

始终生成 `QA-Dashboard.md`，并至少写入：

- `gateMode`。
- 测试覆盖矩阵。
- 已跳过项与原因。
- 所有高影响 Stub 的当前处理方式。
- 一个保守且可追溯的 `readinessScore`。

`readinessScore` 使用统一规则计算：

- 基础分为 `100`。
- 每个 `critical-stub` 扣 `15` 分。
- 每个跳过的高影响场景扣 `10` 分。
- 在 `gateMode: blocking` 下，每个未覆盖的阻断项再扣 `20` 分。
- 最低分不低于 `0`。

如果无法准确统计某一项，不要编造数字；改为将 `readinessScore` 标记为 `pending`，并在 `assumptions` 中写明原因。

### 8. 在输出前做可执行性自检

输出前至少检查以下内容：

- 所有引用的测试工具、快照库、mock 类型是否真实存在。
- 若不存在对应框架，是否已经降级为计划或骨架。
- 是否错误地把 `advisory` 模式写成了 `blocking`。
- 事务注入测试是否只针对真实存在的失败入口。

若无法自检通过，优先保留测试计划和 dashboard，不要伪造可运行测试。

## 输出合同

- `Tests/[Domain]/[Feature]/[Page]TestRunner.swift`：页面行为与状态测试。
- `Tests/Snapshots/[Domain]/[Feature]/[Page]StandardSnapshots.swift`：仅在项目已有快照框架时生成。
- `Reports/[Domain]/[Feature]/QA-Dashboard.md`：统一的质量报告与门禁说明。

## 约束与停止条件

- 不要默认项目一定有快照框架、`SwiftData` in-memory store、Combine 状态流或专用测试 DSL。
- 不要为了测试完整度而编造不可运行的 mock 基建。
- 默认保护迭代节奏；只有在明确进入发布门禁阶段时才启用 `blocking` 行为。
- 若共享报告缺失，先输出最小测试矩阵与缺失项，不要假装已经拿到完整上游产物。
