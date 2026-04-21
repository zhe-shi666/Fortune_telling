# API

这个文件记录当前 app 的后端接口契约。它用于支撑零人工或低人工介入开发，不要求一开始就完全准确，但必须足够支持页面、逻辑和测试阶段继续推进。

## 1. 接口总原则

- 默认只定义 MVP 需要的最小接口集合。
- 当前命理页允许先使用本地保守推演服务驱动，但仍需保留最小 API v0 假设，方便后续接真服务。
- 所有推断出的接口都显式标记为假设，不伪装成已确认后端。
- 充值相关接口当前仅保留未来真实内购的页面契约，不表示本轮接入真实支付。

## 2. 鉴权与会话

- 当前 MVP 默认匿名可用，不要求登录。
- 不要求 token；如果后端未来需要鉴权，优先考虑设备级匿名会话。
- 命主档案当前本地优先保存，不依赖会话恢复。
- 会话过期处理：当前不实现；若未来后端引入会话，统一退回匿名态并提示重新获取数据。

## 2.5 本地版数据接口假设

- 当前本地版不直接连真实后端，页面与服务先通过 `SwiftData` 仓储接口读取档案、权益、收藏和知识库种子。
- 本地数据库由 iOS 放在应用沙盒容器内，开发实现不手写固定绝对路径。
- 这些仓储接口是对未来正式后端的保守等价物，目的是先把 MVP 逻辑闭环跑通。
- 四类命理结果当前在端上由统一算法引擎实时计算，再叠加本地知识库做解释文案映射；因此“知识库读取接口”和“结果生成接口”在职责上已经分离。

本地仓储最小契约：

| Name | Input | Output | 用途 |
| --- | --- | --- | --- |
| `loadProfile/saveProfile` | `ProfileSnapshot` | `ProfileSnapshot?` | 保存与读取命主档案 |
| `loadEntitlement/consumeEntitlement` | `FortuneUsageFeature` | `FortuneEntitlementSnapshot` | 读取灵玉与 VIP，并在命理动作时扣减灵玉 |
| `loadFavorites/toggleFavorite` | `NamingCandidateContent` | `[NamingCandidateContent]` | 维护取名收藏清单 |
| `loadDailyKnowledge` | - | `[DailyGuidanceKnowledge]` | 提供今日签语、本地宜忌与节律模板 |
| `loadBaziKnowledge` | - | `[BaziInsightKnowledge]` | 提供五行解释模板 |
| `loadNamingKnowledge` | - | `NamingLexiconKnowledge` | 提供姓氏与雅名词库 |
| `loadCompatibilityKnowledge` | - | `[CompatibilityTemplateKnowledge]` | 提供合婚分段文案模板 |

## 3. 通用响应约定

- 成功响应格式：

```json
{
  "success": true,
  "data": {},
  "message": "",
  "requestId": "req_123",
  "timestamp": "2026-04-18T09:41:00Z"
}
```

- 错误响应格式：

```json
{
  "success": false,
  "message": "profile required",
  "requestId": "req_123",
  "error": {
    "code": "PROFILE_REQUIRED",
    "details": {}
  }
}
```

- 时间字段格式：统一使用 ISO8601。
- 当前 MVP 接口默认不做分页；若未来名字推荐列表扩展，再补分页约定。

## 4. 错误语义

| Code | HTTP | 含义 | 前端处理 |
| --- | --- | --- | --- |
| `PROFILE_REQUIRED` | 400 | 缺少完整命主档案 | 进入 `empty` 引导态，提示先补档案 |
| `VALIDATION_ERROR` | 422 | 输入字段不完整或格式错误 | 高亮当前输入并阻止继续 |
| `CALCULATION_UNAVAILABLE` | 503 | 当前测算服务不可用 | 展示错误卡并允许重试 |
| `ENTITLEMENT_REQUIRED` | 402 | 灵玉不足或需要 VIP 权益 | 阻止继续，并引导查看充值页 |
| `PAYMENT_NOT_ENABLED` | 501 | 真实支付未启用 | 保持占位页，不重试真实交易 |
| `UNKNOWN_ERROR` | 500 | 未知系统错误 | 展示通用错误态 |

## 5. MVP 接口清单

| Name | Method | Path | 用途 | Auth |
| --- | --- | --- | --- | --- |
| `GetDailyFortune` | GET | `/v1/daily-fortune` | 获取今日运势、宜忌和签语摘要 | `optional` |
| `AnalyzeBazi` | POST | `/v1/bazi/analyze` | 提交出生信息并获取八字测算结果 | `optional` |
| `RecommendNames` | POST | `/v1/naming/recommendations` | 基于出生信息返回名字推荐列表 | `optional` |
| `AnalyzeCompatibility` | POST | `/v1/compatibility/analyze` | 提交双方信息并返回合婚结果 | `optional` |
| `GetRechargePlans` | GET | `/v1/recharge/plans` | 获取充值方案与支付方式展示数据 | `optional` |
| `CreateRechargeOrder` | POST | `/v1/recharge/orders` | 创建充值订单占位契约，当前默认不可用 | `optional` |

## 6. 接口详情

### API: `GetDailyFortune`

- Method: `GET`
- Path: `/v1/daily-fortune`
- Auth: `optional`
- 用途：根据命主档案与日期获取今日运势摘要。
- 触发页面：`Fortune / Daily / TodayOverview`

#### Request

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `profileId` | String | 否 | 若使用本地未上传档案，可为空；服务端模式下用于索引档案 |
| `birthDate` | String | 是 | `YYYY-MM-DD` |
| `birthHourLabel` | String | 是 | 例如 `申时 (15:00-17:00)` |
| `gender` | String | 是 | `男` / `女` |
| `calendarType` | String | 是 | `公历` / `农历` |
| `isLeapMonth` | Bool | 否 | 当 `calendarType = 农历` 时用于标记是否为闰月 |
| `targetDate` | String | 是 | 查询的目标日期 |

#### Response

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `headline` | String | 是 | 主标题，例如 `黄历今朝` |
| `ganzhiLabel` | String | 是 | 标题标签，例如 `今日干支` |
| `ganzhiValue` | String | 是 | 干支值 |
| `updateHint` | String | 否 | 更新时间提示 |
| `recommendedItems` | [String] | 是 | 宜做事项 |
| `cautionItems` | [String] | 是 | 忌做事项 |
| `oraclePreview` | String | 是 | 今日签语摘要 |
| `oracleDetail` | Object | 否 | 解签弹层详情 |

#### Errors

- `400 PROFILE_REQUIRED`
- `503 CALCULATION_UNAVAILABLE`
- `500 UNKNOWN_ERROR`

### API: `AnalyzeBazi`

- Method: `POST`
- Path: `/v1/bazi/analyze`
- Auth: `optional`
- 用途：提交出生信息后返回四柱和五行结果。
- 触发页面：`Fortune / Analysis / BaziAnalysis`

#### Request

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `birthDate` | String | 是 | 出生日期 |
| `birthHourLabel` | String | 是 | 出生时辰 |
| `gender` | String | 是 | 生理性别 |
| `calendarType` | String | 是 | 历法类型；当前支持公历与农历 |
| `isLeapMonth` | Bool | 否 | 当 `calendarType = 农历` 时用于标记是否为闰月 |

#### Response

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `pillars` | [Object] | 是 | 四柱信息 |
| `fiveElements` | [Object] | 是 | 五行强弱列表 |
| `summary` | String | 是 | 结果摘要 |

#### Errors

- `422 VALIDATION_ERROR`
- `503 CALCULATION_UNAVAILABLE`

### API: `RecommendNames`

- Method: `POST`
- Path: `/v1/naming/recommendations`
- Auth: `optional`
- 用途：基于出生信息返回一组名字建议。
- 触发页面：`Fortune / Naming / NamingWorkshop`

#### Request

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `birthDate` | String | 是 | 出生日期 |
| `surname` | String | 否 | 姓氏；若填写，返回的推荐名字必须使用该姓氏 |
| `gender` | String | 是 | `男` / `女`；当前取名排序会把它作为候选约束条件 |
| `birthHourLabel` | String | 是 | 出生时辰；当前取名页已显式采集，为命理计算必填项 |
| `limit` | Int | 否 | 建议数量，默认 `4` |

#### Response

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `candidates` | [Object] | 是 | 名字建议列表 |
| `favorites` | [Object] | 否 | 已收藏名字列表，当前也可由本地维护 |

#### Errors

- `422 VALIDATION_ERROR`
- `503 CALCULATION_UNAVAILABLE`

### API: `AnalyzeCompatibility`

- Method: `POST`
- Path: `/v1/compatibility/analyze`
- Auth: `optional`
- 用途：提交双方生辰后返回合婚推演结果。
- 触发页面：`Fortune / Compatibility / CompatibilityReading`

#### Request

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `maleProfile` | Object | 是 | 男方生辰信息 |
| `femaleProfile` | Object | 是 | 女方生辰信息 |

#### Response

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `score` | Int | 是 | 契合度分值 |
| `summaryLines` | [String] | 是 | 推演结果摘要列表 |

#### Errors

- `422 VALIDATION_ERROR`
- `503 CALCULATION_UNAVAILABLE`

### API: `GetRechargePlans`

- Method: `GET`
- Path: `/v1/recharge/plans`
- Auth: `optional`
- 用途：获取充值页面展示所需的余额、套餐和支付方式。
- 触发页面：`Commerce / Recharge / RechargeCenter`

#### Request

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `locale` | String | 否 | 文案本地化用，当前可省略 |

#### Response

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `balance` | String | 是 | 当前灵玉余额展示值 |
| `membership` | String | 是 | 当前权益状态，如 `按次消耗` / `VIP 畅用中` |
| `plans` | [Object] | 是 | 充值方案列表 |
| `paymentMethods` | [Object] | 是 | 支付方式列表 |

#### Errors

- `500 UNKNOWN_ERROR`

### API: `CreateRechargeOrder`

- Method: `POST`
- Path: `/v1/recharge/orders`
- Auth: `optional`
- 用途：为未来真实支付保留的最小契约；当前默认不可用。
- 触发页面：`Commerce / Recharge / RechargeCenter`

#### Request

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `planId` | String | 是 | 充值方案 ID |
| `paymentMethod` | String | 是 | 支付方式 |

#### Response

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `orderId` | String | 是 | 订单 ID |
| `status` | String | 是 | 当前应返回 `paymentDisabled` 或未来真实状态 |

#### Errors

- `501 PAYMENT_NOT_ENABLED`

## 7. 前端映射

| Domain | Feature | Page | API | 对应动作 |
| --- | --- | --- | --- | --- |
| Fortune | Daily | TodayOverview | `GetDailyFortune` | 加载今日运势、展示解签 |
| Fortune | Analysis | BaziAnalysis | `AnalyzeBazi` | 扣减 1 灵玉后触发八字测算 |
| Fortune | Naming | NamingWorkshop | `RecommendNames` | 每次生成前扣减 1 灵玉 |
| Fortune | Compatibility | CompatibilityReading | `AnalyzeCompatibility` | 扣减 1 灵玉后触发合婚推演 |
| Commerce | Recharge | RechargeCenter | `GetRechargePlans`, `CreateRechargeOrder` | 展示充值方案、创建订单占位 |

## 8. 当前已知假设与风险

- `GetDailyFortune` 是当前首个 feature 的核心 v0 接口，但本轮代码优先使用本地保守推演服务驱动。
- 命主档案当前默认本地保存，未单独定义 `profile` 网络接口；如果后续需要云同步，再补契约。
- `CreateRechargeOrder` 只是为了阻止后续逻辑层“凭空创造”支付接口；当前明确不可用，未来将优先接入 Apple In-App Purchase。
- 本地版当前通过 `SwiftData` 仓储接口承接页面逻辑，并内置静态知识种子；后续切到真实后端时，需要为知识库、权益账本和内容版本建立正式远程接口。
- 所有路径、字段名和错误码都属于 v0 假设，后续应以真实后端文档收敛。
