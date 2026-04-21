# Domain

这个文件只记录当前 app 的领域信息。它不负责写技术栈，也不负责写项目通用规则。

## 1. 核心实体

| Entity | 说明 | 主标识 | 核心状态 |
| --- | --- | --- | --- |
| `ProfileRecord` | 命主档案，驱动今日、八字、取名、合婚的输入基础 | `profileId` | `profileMissing` / `profileReady` |
| `DivinationResult` | 今日运势、八字测算、取名结果、合婚结果的统一展示载体 | `resultId` | `idle` / `loading` / `ready` / `failed` |
| `FortuneEntitlement` | 灵玉余额与 VIP 权益状态，控制解签、八字、取名、合婚的使用资格 | `walletId` | `payPerUse` / `vipUnlimited` / `insufficientJade` |
| `RechargeIntent` | 充值页面中的方案与支付方式选择，用于未来真实内购，不代表当前已完成支付 | `intentId` | `planUnselected` / `planSelected` / `paymentMethodSelected` / `paymentDisabled` |
| `LocalKnowledgeSeed` | 本地命理知识库的种子版本标记，用于控制签语、五行解释、取名词库、合婚文案的初始化与升级 | `seedKey` | `missing` / `ready` / `outdated` |

## 2. 实体字段

### Entity: `ProfileRecord`

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `profileId` | String | 是 | 本地档案唯一标识 |
| `birthDate` | String | 是 | 出生日期，当前统一使用 `YYYY-MM-DD` 文本格式 |
| `birthHourLabel` | String | 是 | 出生时辰，如 `申时 (15:00-17:00)` |
| `gender` | String | 是 | 当前仅保守支持 `男` / `女` 文本值 |
| `calendarType` | String | 是 | `公历` 或 `农历` |
| `isLeapMonth` | Bool | 否 | 当 `calendarType = 农历` 时用于标记是否为闰月，公历输入固定为 `false` |
| `lastUpdatedAt` | String | 否 | 最近保存时间，用于页面提示 |

### Entity: `DivinationResult`

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `resultId` | String | 是 | 结果唯一标识 |
| `resultType` | String | 是 | `daily` / `analysis` / `naming` / `compatibility` |
| `scenario` | String | 是 | 统一使用 `ideal` / `loading` / `empty` / `error` |
| `headline` | String | 否 | 页面主标题或摘要，如今日签语、名字标题 |
| `summary` | String | 否 | 结果摘要文本 |
| `highlights` | [String] | 否 | 宜忌、五行、兼容要点或名字理由 |
| `score` | Int | 否 | 若页面存在分值或兼容度时使用 |
| `generatedAt` | String | 否 | 生成时间，便于提示结果是否过时 |

### Entity: `FortuneEntitlement`

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `walletId` | String | 是 | 本地权益钱包唯一标识 |
| `jadeBalance` | Int | 是 | 当前可用灵玉余额 |
| `isVIPActive` | Bool | 是 | 是否处于 VIP 无限使用状态 |
| `membershipLabel` | String | 是 | 页面展示用权益文案，如 `按次消耗` / `VIP 畅用中` |

### Entity: `RechargeIntent`

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `intentId` | String | 是 | 当前选择流程的唯一标识 |
| `planId` | String | 否 | 充值方案标识 |
| `paymentMethod` | String | 否 | 支付方式标识，如 `wechat` / `alipay` |
| `displayPrice` | String | 否 | 仅用于 UI 展示的价格文案 |
| `status` | String | 是 | 当前充值选择状态 |

## 3. 状态枚举

### 通用状态

- `ideal`
- `loading`
- `empty`
- `error`

### 业务状态

- `profileMissing`：未找到可用命主档案，今日页应降级为引导态。
- `profileReady`：档案完整，可用于今日/八字/取名/合婚的后续计算。
- `resultReady`：结果已可展示。
- `resultFailed`：结果获取失败，应提示重试。
- `paymentDisabled`：真实支付未启用，只允许展示占位流程。

## 4. 实体关系

- `ProfileRecord` 驱动多个 `DivinationResult`，其中 `TodayOverview`、`BaziAnalysis`、`NamingWorkshop`、`CompatibilityReading` 都读取同一份档案。
- `FortuneEntitlement` 同时影响 `TodayOverview` 的解签、`BaziAnalysis` 的合取测算、`NamingWorkshop` 的取名生成、`CompatibilityReading` 的合婚推演。
- `RechargeIntent` 与 `ProfileRecord` 没有强绑定关系，但会影响未来高级能力的可用状态；当前 MVP 仅保留页面层关系。
- `NamingWorkshop` 的收藏名字清单是本地独立持久化集合，当前与 `DivinationResult(resultType = naming)` 弱关联，但在存储层已作为可复用数据表处理。
- `LocalKnowledgeSeed` 管理本地知识库版本，确保每日签语规则、八字解释模板、取名词库、合婚文案模板可以首启自动生成，并在后续版本安全升级。

## 5. 关键业务规则

- 没有 `ProfileRecord` 时，`TodayOverview` 不能伪造用户专属运势，必须进入 `empty` 引导态。
- `ProfileRecord` 的 `birthDate`、`birthHourLabel`、`gender`、`calendarType` 四项是最小完整集；缺任一项都视为档案未准备好。
- 今日、八字、取名、合婚的结果当前允许来自保守推断，但必须明确这只是娱乐参考或辅助参考，不是专业命理结论。
- 取名收藏清单当前要求本地持久化展示，不要求多端同步和账号绑定。
- 本地版本默认采用 `SwiftData` 持久化，数据库由 iOS 放在应用沙盒容器内；当前不开放用户自定义路径，也不做 iCloud 同步。
- 本地知识库当前由 App 首次启动时自动生成，属于静态种子数据，不代表真实命理权威数据库。
- 今日、八字、取名、合婚的最终展示结果，当前统一由“实时算法结果 + 本地知识库映射文案”组合而成；知识库负责解释与收束，不直接替代实时测算。
- 今日信号、八字五行/格局、合婚契合分、取名候选分值当前都保留结构化命中依据，便于后续做黄金样例校对、回归测试和后端替换。
- `NamingWorkshop` 新增姓氏与性别输入；若用户填写姓氏，生成结果必须使用该姓氏；若修改姓氏、性别、出生日期或出生时辰，当前推荐应立即清空。
- `NamingWorkshop` 当前将性别、出生日期与出生时辰都视为显式必填输入，不再使用午时回落近似方案。
- `NamingWorkshop` 的候选结果需要受输入性别约束；允许保留中性风格名字，但不应让明显不匹配的性别风格候选长期占据推荐前列。
- `TodayOverview` 的解签、`BaziAnalysis` 的合取测算、`NamingWorkshop` 的每次取名生成、`CompatibilityReading` 的合婚推演，当前统一消耗 1 灵玉。
- 当 `FortuneEntitlement.isVIPActive = true` 时，上述四类动作不再扣减灵玉，按无限使用处理。
- 当灵玉余额不足且 VIP 未激活时，命理动作必须被拦截，并提示用户前往充值页查看权益方案。
- `RechargeIntent` 当前只允许记录方案与支付方式选择，并在提交时展示购买说明文案；不允许触发真实扣费、支付状态轮询或财务账本写入。
- 失败重试优先区分：
  - 档案缺失：可重试，但应先补资料。
  - 计算服务不可用：可重试。
  - 真实支付未启用：强失败，不自动重试。

## 6. 高影响动作

- 创建或更新 `ProfileRecord`
- 触发今日运势计算
- 触发八字测算
- 触发取名推荐
- 触发合婚推演
- 收藏或取消收藏名字
- 选择充值方案或支付方式
- 写入本地持久层

## 7. 报告与测试映射

| Domain | Feature | Page | 关键实体 | 高影响动作 | 关键测试 |
| --- | --- | --- | --- | --- | --- |
| Fortune | Daily | TodayOverview | `ProfileRecord`, `DivinationResult` | 读取档案、请求今日结果、打开解签面板 | 档案缺失态、结果成功态、失败态、解签显隐 |
| Fortune | Analysis | BaziAnalysis | `ProfileRecord`, `DivinationResult` | 提交生辰信息、触发测算 | 输入缺失、结果渲染、错误提示 |
| Fortune | Naming | NamingWorkshop | `ProfileRecord`, `DivinationResult` | 生成名字、打开收藏清单、收藏切换 | 必填性别/出生日期/时辰、推荐列表、收藏弹层 |
| Fortune | Compatibility | CompatibilityReading | `ProfileRecord`, `DivinationResult` | 提交双方信息、触发合婚推演 | 双方输入校验、结果卡展示 |
| Commerce | Recharge | RechargeCenter | `RechargeIntent` | 选择套餐、选择支付方式 | 占位充值流程、返回路径 |
| Profile | MasterProfile | ProfileEditor | `ProfileRecord` | 保存档案 | 保存前校验、保存后回流 |

## 8. 当前已知风险

- 命理算法已切到本地结构化分析底座，且公历、普通农历与农历闰月输入都已接通；但黄金样例校对仍未完成，当前仍不能宣称达到完整传统命理级精度。
- 后端接口尚未最终确定；当前本地版已改为 `SwiftData` 持久化，并包含从旧 `UserDefaults` 键值迁移到本地数据库的保守策略。
- 真实支付不在本轮实现范围内，但页面存在未来内购入口，后续需要单独处理 StoreKit、合规与交易安全。
- 设计稿已给出字段名和排版方向，但未完整定义所有空态、错误态 UI，当前需要在页面与测试报告里保守降级。
- 本地知识库只是演示到商业化过渡阶段的离线规则集；如果后续要做可运营版本，仍需要后端数据源、内容审核与版本下发能力。
