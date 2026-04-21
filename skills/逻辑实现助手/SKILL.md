---
name: 逻辑实现助手
description: 将页面 Contract、现有服务层和交互需求转换为中小型 iOS 项目的 ViewModel、依赖注入、事务流程与 logic-report.md。适用于生成或重构业务逻辑、状态机和事务型流程，尤其适合消费页面生成助手产出的 MockScenario、confidence 与 ui-layout-report.md。
---

# 逻辑实现助手

把页面契约落成可维护、可降级、可继续测试的业务逻辑，并为测试阶段产出稳定的共享报告。

## 共享协议

与页面生成助手、测试助手协同时，统一消费和产出以下字段：

- `MockScenario`：仅使用 `ideal`、`loading`、`empty`、`error`。
- `confidence`：使用 `0.0 ... 1.0` 浮点数，并严格按阈值消费：
  - `>= 0.85`：可按正常业务流实现
  - `0.60 ... 0.84`：主链路可实现，复杂支线与细节降级
  - `0.40 ... 0.59`：只生成 compile-safe 骨架、关键 Stub 与最小副作用
  - `< 0.40`：不脑补复杂逻辑，只保留占位、阻塞说明或人工确认点
- `complexAdaptation`：布尔值，来自 `ui-layout-report.md`，表示该区域需要额外适配验证。
- `criticality`：仅使用 `high`、`medium`、`low`。
- `gateMode`：仅使用 `advisory`、`blocking`。未明确要求发布门禁时默认 `advisory`。
- `transactionSteps`：有序数组，每一项至少包含 `id`、`name`、`criticality`、`rollbackRequired`。

`logic-report.md` 至少包含以下字段：

```md
# Logic Report

- page: Auth/Login
- gateMode: advisory
- assumptions:
  - 未发现 DomainContainer，改为协议注入

## Critical Stubs
- name: submitLogin
  criticality: high
  blockingRelease: true
  reason: 缺少真实登录 API 协议

## Transaction Steps
- id: step-1
  name: validate-input
  criticality: high
  rollbackRequired: false
- id: step-2
  name: persist-session
  criticality: high
  rollbackRequired: true

## Failure Injection Points
- stepId: step-2
  target: persist-session
  suggestedFailure: throw StorageError.diskFull
```

## 执行流程

### 1. 先读取真实依赖，再决定实现方式

优先读取以下内容：

- 目标页面的 `Contract.swift`。
- `Reports/[Domain]/[Feature]/ui-layout-report.md`，尤其是 `confidence`、`complexAdaptation` 和 `scenarios`。
- `docs/domain.md`，尤其是关键业务规则、高影响动作和已知风险。
- `docs/api.md`，尤其是接口清单、错误语义和当前已知假设。
- 现有 `ViewModel`、`Service`、`Repository`、`Container`、`Coordinator`、`Logger`。

若页面契约不存在，不要直接编造完整业务流；先根据现有 View 和用户描述补出最小假设，并在 `logic-report.md` 的 `assumptions` 中明确记录。

若当前页面明显依赖网络请求，而 `docs/api.md` 仍为空或仍是占位模板，先基于 `docs/domain.md` 与页面语义补出最小接口假设，并把这些假设同步写回 `docs/api.md` 与 `logic-report.md`，再继续生成逻辑骨架。

若逻辑实现过程中反向发现页面范围、业务规则、接口契约或门禁判断已变化，先按 `app -> domain -> api -> 当前阶段报告 -> skill` 的顺序回流更新，再继续实现。

### 2. 先给 Action 分级

按动作影响范围分级，再决定生成强实现还是降级实现：

- 将“提交”“删除”“支付”“同步”“写入本地持久层”等动作标记为 `criticality: high`。
- 将“收起/展开”“局部切换”“次级跳转”等动作标记为 `criticality: low` 或 `medium`。
- 对来自低置信度 UI 区域的动作，优先生成 compile-safe 的占位逻辑，不要硬写复杂副作用。
- 当 `confidence < 0.60` 时，不要反向脑补复杂事务或组合副作用；优先降级为最小可验证主链路。

### 3. 优先复用项目现有注入方式

依赖注入策略按以下顺序选择：

- 若项目已有 `Container`、`Resolver`、`Factory` 或模块注入约定，优先复用。
- 若没有统一容器，优先改为协议注入或构造函数注入。
- 只有在项目已存在父子容器模式时，才生成 `FeatureSubContainer` 一类结构。

不要为了套模板而引入新的 `DomainContainer`、`Coordinator` 或自定义 `Transaction` 包装器。

### 4. 生成可编译的逻辑骨架

生成逻辑代码时遵循以下原则：

- 高影响动作优先落成真实流程；若缺少关键依赖，则生成 compile-safe Stub，并把缺口写进 `logic-report.md`。
- 低影响动作仅保留最少逻辑与日志，不制造过重样板。
- 若项目没有统一 `Logger`，使用最简单的现有日志方式；若也没有，则省略日志，不要自造日志基础设施。

### 5. 仅在条件满足时生成事务实现

只有在项目存在明确的持久化层、可识别的事务边界或服务组合时，才生成事务型代码。

- 若可以识别事务边界，则为每一步生成 `transactionSteps`。
- 若无法安全实现事务，则只生成步骤表、失败点和回滚要求，不编造伪事务 API。
- 若事务涉及多表或多资源写入，优先把“校验”“写入”“回滚要求”拆开写清楚。

### 6. 产出共享报告

始终生成 `logic-report.md`，并至少写入：

- `gateMode`。
- 所有关键假设。
- 所有高影响 Stub。
- `transactionSteps`。
- 推荐给测试助手消费的失败注入点（写入 `## Failure Injection Points`）。

### 7. 在输出前做安全自检

输出前至少检查以下内容：

- `ViewModel` 是否只引用了真实存在的 `State`、`Action` 和依赖。
- 若使用容器、日志器、事务包装器，这些类型是否真实存在于项目中。
- 所有 Stub 是否都已写入 `logic-report.md`。
- 所有高影响未完成逻辑是否都有显式说明。

若无法自检通过，停在 compile-safe 骨架，不要继续补虚构实现。

## 输出合同

- `ViewModels/[Domain]/[Feature]/[Page]ViewModel.swift`：页面对应的主要业务逻辑。
- `Services/[Domain]/[Feature]SubContainer.swift`：仅在项目已有相同模式时生成。
- `Reports/[Domain]/[Feature]/logic-report.md`：供测试助手消费的逻辑报告。

## 约束与停止条件

- 不要默认项目一定有 `DomainContainer`、`Coordinator`、`Logger.logic`、`Transaction.run` 或自定义 `step()` DSL。
- 不要把所有未实现逻辑都包装成巨大的 Stub；仅显式标出真正阻断交付的高影响缺口。
- 若缺少依赖接口、协议或持久化基础设施，优先记录阻塞并交付可编译骨架。
- 若页面输入本身存在低置信度区域，逻辑层也必须同步降级，不要反向脑补复杂业务。
