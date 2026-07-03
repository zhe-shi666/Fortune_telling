# 🏮 Fortune Telling（命理测算）

> 一款基于传统东方命理学的 iOS 娱乐参考 App，帮助用户查看每日运势、八字测算、取名建议与合婚推演。

**⚠️ 免责声明：本 App 所有测算结果仅供娱乐参考，不构成专业命理结论。**

---

## 📱 项目简介

Fortune Telling 是一款面向对东方命理感兴趣的中文用户的 iOS App。用户通过建立一份命主档案（出生日期、时辰、性别、历法），即可快速查看今日运势，并完成八字分析、取名、合婚等命理测算。

当前版本为 **MVP 闭环**，涵盖 6 个核心页面，采用本地算法引擎 + SwiftData 持久化的离线优先策略。

### 设计稿预览

![UI设计图](docs/screenshot.png)

---

## ✨ 核心功能

| 模块 | 页面 | 功能描述 |
|------|------|----------|
| 🎯 今日 | TodayOverview | 展示今日干支、宜忌事项、签语预览，支持解签弹层 |
| 📊 八字 | BaziAnalysis | 录入出生信息后计算四柱、五行强弱、十神与格局分析 |
| ✏️ 取名 | NamingWorkshop | 基于生辰八字生成名字建议，支持收藏清单管理 |
| 💑 合婚 | CompatibilityReading | 录入双方信息后推演契合度、夫妻宫关系与格局互动 |
| 💰 充值 | RechargeCenter | 灵玉余额与 VIP 权益管理，内购方案展示 |
| 👤 命主 | ProfileEditor | 保存并管理命主档案，作为所有测算页面的输入基础 |

### 权益体系

- **灵玉（Jade）**：每次解签/测算/取名/合婚消耗 1 灵玉
- **VIP 会员**：无限使用所有测算功能，不扣减灵玉
- 充值页面当前仅保留 UI 骨架与购买说明文案，**未接入真实支付**

---

## 🏗️ 技术架构

| 维度 | 选型 |
|------|------|
| 平台 | iOS 17+ |
| 语言 | Swift 6+（严格并发检查） |
| UI 框架 | SwiftUI |
| 架构模式 | MVVM + Coordinator |
| 持久化 | SwiftData |
| 网络 | URLSession + Codable（本地版暂不联网） |
| 依赖管理 | Swift Package Manager |

### 项目结构

```
Fortune_telling/
├── AGENTS.md                    # 总控文件（AI 驱动开发规则）
├── CLAUDE.md                    # 跳转至 AGENTS.md
├── 启动prompt.md                 # 项目启动提示词模板
├── README.md
├── docs/
│   ├── rules.md                 # 项目通用规则
│   ├── app.md                   # 产品范围与 MVP 定义
│   ├── domain.md                # 领域实体与业务规则
│   ├── api.md                   # 接口契约（v0 假设）
│   ├── 算法规格-v1.md            # 传统命理算法规格
│   ├── 使用手册.md               # 三阶段开发使用手册
│   ├── 发布收口清单.md           # 发布 checklist
│   ├── 商业化TODO清单.md         # 商业化待办
│   ├── 隐私政策-v0.md            # 隐私政策草案
│   └── screenshot.png           # 设计稿截图
├── FortuneTelling/
│   ├── App/                     # App 入口、Coordinator 路由
│   ├── Views/                   # 页面视图（6 个 Feature）
│   ├── ViewModels/              # 视图模型
│   ├── Services/                # 业务服务层
│   │   └── Fortune/Algorithm/   # 命理算法引擎（核心）
│   ├── Contracts/               # 页面契约与路由协议
│   ├── Shared/DesignSystem/     # 设计系统（主题、配色、字体）
│   ├── Mocks/                   # Mock 数据工厂
│   ├── Resources/KnowledgeBase/ # 本地命理知识库
│   └── Assets.xcassets/        # 资源文件
├── FortuneTellingTests/         # 测试文件
├── Reports/                     # 各阶段报告
│   ├── Fortune/Daily/           # 今日页面报告
│   ├── Fortune/Analysis/        # 八字页面报告
│   ├── Fortune/Naming/          # 取名页面报告
│   ├── Fortune/Compatibility/   # 合婚页面报告
│   ├── Fortune/AlgorithmFoundation/ # 算法底座报告
│   ├── Fortune/LocalData/       # 本地数据报告
│   ├── Commerce/Recharge/       # 充值页面报告
│   └── Profile/MasterProfile/   # 命主页面报告
└── skills/                      # AI 辅助开发 Skill
    ├── 页面生成助手/
    ├── 逻辑实现助手/
    └── 测试助手/
```

---

## 🧮 算法引擎

项目内置了一套完整的传统命理算法引擎 `FortuneAlgorithmEngine`，核心能力包括：

- **八字排盘**：公历/农历/农历闰月输入 → 四柱（年柱、月柱、日柱、时柱）
- **真太阳时校正**：基于经纬度的均时差与经度偏移计算
- **节气推算**：12 个主要节气的二分搜索精确定位
- **五行量化**：天干地支 + 藏干加权 + 月令季节调候
- **十神分析**：比肩、劫财、食神、伤官、偏财、正财、七杀、正官、偏印、正印
- **日主强弱**：月令扶抑 + 根气承托 + 透干助制 + 量化平衡四维判断
- **格局识别**：伤官配印、杀印相生、食神生财、官印相生、身强取泄、扶抑平衡
- **今日运势**：流日五行与命局的生克冲合刑害分析 → 宜忌标签
- **取名推荐**：五行贴合 + 音律节奏 + 字义气质 + 性别匹配 + 风格协调的多维评分
- **合婚推演**：喜用契合、夫妻宫关系、日主互动、地支互动、格局互动的综合评分

> 算法底座已支持公历、普通农历与农历闰月输入；但黄金样例校对仍在进行中，当前结果统一标注为娱乐参考。

---

## 🚀 快速开始

### 环境要求

- macOS 15+
- Xcode 17+
- iOS 17.0+ 模拟器或真机

### 运行项目

1. 克隆仓库：
   ```bash
   git clone git@github.com:zhe-shi666/Fortune_telling.git
   ```

2. 用 Xcode 打开 `FortuneTelling.xcodeproj`

3. 选择 iOS 17.0+ 模拟器，按 `⌘R` 运行

4. App 启动后直接进入「今日」页面，可通过底部导航切换四个主页面

---

## 📋 MVP 进度

| 页面 | 页面骨架 | 逻辑实现 | 测试 | 状态 |
|------|:---:|:---:|:---:|:---:|
| TodayOverview（今日） | ✅ | ✅ | ✅ | advisory |
| BaziAnalysis（八字） | ✅ | ✅ | ✅ | — |
| NamingWorkshop（取名） | ✅ | ✅ | ✅ | — |
| CompatibilityReading（合婚） | ✅ | ✅ | ✅ | — |
| RechargeCenter（充值） | ✅ | ✅ | ✅ | — |
| ProfileEditor（命主） | ✅ | ✅ | ✅ | — |

---

## 🔮 当前不做（MVP 范围外）

- 账号体系、登录注册、多端同步
- 真实支付 SDK、订单回调、发票、退款
- 社区分享、社交关系、消息推送
- 复杂后台管理、运营位配置、A/B 实验
- 专业命理公式校验与专家人工服务

---

## 📄 许可证

本项目仅供学习与娱乐参考使用。
