# QA Dashboard

- page: Fortune/Naming/NamingWorkshop
- gateMode: advisory
- readinessScore: 95
- scoreBreakdown: base 100, -3 (syncNameRecommendationsToBackend pending), -2 (favorites sync pending)
- assumptions:
  - 收藏面板当前为保守 modal 版本，测试只验证状态、数据与离线候选确定性，不做动画断言。
  - 取名候选已切到统一算法底座，当前已把性别与出生时辰纳入显式输入与校验。

## Coverage
- scenarios: ideal, loading, empty, error
- transactionStepsCovered: step-1, step-2, step-3, step-4, step-5, step-6

## Matrix
- `ideal`: 有出生日期时首次点击生成 2 个候选名字
- `required-gender`: 未选择性别时，不允许直接触发生成
- `required-hour`: 缺少出生时辰时，不允许直接触发生成
- `surname-validation`: 非中文或超过 2 个字的姓氏不应通过生成校验
- `surname`: 填写姓氏后，生成结果必须使用输入的姓氏
- `gender-constraint`: 相同日期、时辰、姓氏下切换性别，候选排序应发生变化
- `incremental`: 同一日期再次点击继续追加 2 个名字
- `entitlement`: 普通用户每次点击生成都会消耗 1 灵玉；同日期继续追加也走同一扣减规则
- `reset`: 更换出生日期、出生时辰、性别或姓氏时立即清空当前推荐，并在再次点击后从 2 个重新开始
- `deterministic`: 相同出生日期与姓氏重复生成得到相同候选顺序
- `score-distribution`: 候选分值应存在区分度，不能全部顶格为同一分值
- `algorithm-summary`: 候选卡需带出非空的命理补益摘要
- `empty`: 缺少出生日期时停留在等待输入态
- `favorite`: 点击心形按钮后收藏列表更新
- `persist`: 收藏写入后可在新 store 实例中读回
- `error`: 服务失败时给出错误提示

## Skipped
- item: 收藏面板动效测试
  reason: 当前实现按保守 overlay 降级，不承诺最终动画
- item: 快照测试
  reason: 工程未引入快照测试框架

## Warnings
- type: pending-sync
  target: syncNameRecommendationsToBackend
  action: 后续接真接口后需校正候选名字、五行摘要与分值断言
- type: pending-sync
  target: persistFavoriteNames
  action: 当前已支持本地持久化；若未来需要账号同步，还需补齐服务端收藏契约
