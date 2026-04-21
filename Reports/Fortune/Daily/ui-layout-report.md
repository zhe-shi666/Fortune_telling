# UI Layout Report

- page: Fortune/Daily/TodayOverview
- contract: FortuneTelling/Contracts/Fortune/Daily/TodayOverviewContract.swift
- scenarios: ideal, loading, empty, error
- assumptions:
  - UI 结构来自当前打开的 Pencil MCP 设计树 `Fortune Mobile Web`，并非截图推断。
  - 设计中的系统状态栏与设备容器已剥离，不生成业务组件。
  - 设计字体 `Playfair Display`、`Newsreader` 当前以系统 serif 风格近似。
  - `命主档案缺失态`、`加载态`、`错误态` 未在 Pencil 中完整展开，当前按页面生成助手规则保守降级。

## Regions
- id: top-quick-actions
  confidence: 0.95
  complexAdaptation: false
  fallback: 无，直接按 Pencil 的 `档` / `充` 小按钮实现
- id: oracle-overlay
  confidence: 0.92
  complexAdaptation: false
  fallback: 保留为页内自绘遮罩与底部浮层，不引入额外导航层
- id: empty-state
  confidence: 0.42
  complexAdaptation: false
  fallback: 使用同一视觉语言生成引导卡片，提示先补命主档案
- id: error-state
  confidence: 0.46
  complexAdaptation: false
  fallback: 使用保守错误卡与重试按钮，不强推复杂失败插画
- id: loading-state
  confidence: 0.58
  complexAdaptation: false
  fallback: 使用与理想态一致的卡片骨架并套用 redacted

## Reuse
- reused: FortuneTelling/Shared/DesignSystem/FortuneTheme.swift
- reused: FortuneTelling/Shared/Models/MockScenario.swift
- reused: FortuneTelling/Contracts/Fortune/Daily/TodayOverviewContract.swift

## Notes

- 底部导航只实现 `今日 / 八字 / 合婚 / 取名` 四个主入口；本轮未展开的页面统一进入占位页。
- `充值页面` 与 `命主页面` 在本轮只保留路由壳，避免同时推进多个 feature。
