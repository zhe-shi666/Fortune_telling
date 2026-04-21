# QA Dashboard

- page: Fortune/AlgorithmFoundation/Core
- gateMode: advisory
- readinessScore: 100
- scoreBreakdown: base 100
- assumptions:
  - 当前已在 `iPhone 17 / iOS Simulator 26.4` 上完成真实执行态 XCTest，不再停留在仅 `build-for-testing` 的阶段。
  - 算法正确性当前优先验证“结构完整、同输入稳定输出、边界不崩溃”，不宣称已经达到传统命理全流派一致。
  - 取名页已补显式出生时辰输入；当前主要精度缺口已从输入表达收敛到后续黄金样例校对。

## Coverage
- scenarios: ideal, empty, error
- transactionStepsCovered: step-1, step-2, step-3, step-4, step-5, step-6, step-7

## Matrix
- `bazi-structure`: 八字结果必须稳定产出四柱、五行分值和解释文本
- `bazi-trace`: 八字结果必须稳定产出五行拆解与格局候选
- `daily-structure`: 今日结果必须稳定产出干支值、宜忌、签语和解签分类
- `daily-trace`: 今日结果必须稳定产出流日信号命中和知识规则匹配
- `compatibility-structure`: 合婚结果必须稳定产出分值、夫妻宫判断和三段摘要
- `compatibility-render-trace`: 合婚模板匹配必须可重复命中同一知识规则
- `naming-structure`: 取名结果必须稳定产出 8 个候选，且尊重输入姓氏
- `naming-breakdown`: 取名候选必须稳定产出多维得分拆解，并经映射层生成展示摘要
- `lunar-equivalence`: 已知农历日期输入应与等价公历日期落到同一四柱分析
- `lunar-leap-equivalence`: 已知农历闰月输入应与等价公历日期落到同一四柱分析
- `lichun-boundary`: 立春前后样例应正确切换年柱
- `true-solar-hour-shift`: 不同经度下真太阳时修正可导致时柱切换
- `deterministic`: 同一输入重复执行时，结果结构和关键信息不应随机漂移

## Skipped
- none

## Warnings
- type: precision-gap
  target: golden-reference-regression
  action: 当前已补第一轮黄金样例与边界回归；若继续追求传统命理级精度，应再引入更权威历法底座做交叉校验
- type: toolchain-noise
  target: appintentsmetadataprocessor
  action: `Metadata extraction skipped. No AppIntents.framework dependency found.` 来自 Xcode 工具链日志，不影响当前构建、运行与测试结果
