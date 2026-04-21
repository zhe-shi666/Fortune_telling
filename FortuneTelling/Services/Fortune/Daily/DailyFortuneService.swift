import Foundation

struct OracleDetailPayload: Equatable, Sendable {
    var title: String
    var category: String
    var body: String
    var adviceTitle: String
    var adviceBody: String
    var triggerHint: String
    var secondaryButtonTitle: String
    var primaryButtonTitle: String
}

struct DailyFortunePayload: Equatable, Sendable {
    var heroTitle: String
    var heroSubtitle: String
    var ganzhiLabel: String
    var ganzhiValue: String
    var updateHint: String
    var recommendedLine: String
    var cautionLine: String
    var oracleTitle: String
    var oraclePreview: String
    var oracleDetail: OracleDetailPayload

    static func sample(for profile: ProfileSnapshot, on date: Date) -> DailyFortunePayload {
        let formatter = ISO8601DateFormatter()
        let _ = formatter.string(from: date)

        return DailyFortunePayload(
            heroTitle: "黄历今朝",
            heroSubtitle: "且把浮尘收作墨，一纸吉时写从容。",
            ganzhiLabel: "今日干支",
            ganzhiValue: "乙巳年 · 三月初九",
            updateHint: "戌时再校",
            recommendedLine: "宜：祈福、会友、定约",
            cautionLine: "忌：夜行、口舌、仓促决策",
            oracleTitle: "今日签语",
            oraclePreview: "签曰：守正藏锋，静候东风。晚间有贵人解你心结。",
            oracleDetail: OracleDetailPayload(
                title: "今日解签",
                category: "上签 · 云开月见",
                body: "今日宜守心静气，缓步而行。所求之事渐有回应，先稳后进，自得其成。",
                adviceTitle: "解签提示",
                adviceBody: "先处理手头最重要的一件事，再推进新的计划，运势会更顺。",
                triggerHint: "由今日签语下方“解签”按钮触发",
                secondaryButtonTitle: "稍后再看",
                primaryButtonTitle: "查看详解"
            )
        )
    }
}

struct DailyFortuneRenderContext: Equatable, Sendable {
    var matchedRule: DailyGuidanceKnowledge
    var matchScore: Int
    var matchBreakdown: [FortuneScoreComponent]
    var tieBreaker: UInt64

    static func resolve(
        insight: FortuneDailyInsight,
        knowledge: [DailyGuidanceKnowledge]
    ) -> DailyFortuneRenderContext {
        let fallbackRule = knowledge[0]
        let selectionSeed = tieBreakSeed(for: insight)
        return knowledge.map { rule in
            let breakdown = ruleBreakdown(rule, insight: insight)
            return DailyFortuneRenderContext(
                matchedRule: rule,
                matchScore: breakdown.reduce(0) { $0 + $1.score },
                matchBreakdown: breakdown,
                tieBreaker: stableHash(selectionSeed + "|" + rule.ruleId)
            )
        }.max { lhs, rhs in
            if lhs.matchScore == rhs.matchScore {
                if lhs.tieBreaker == rhs.tieBreaker {
                    return lhs.matchedRule.ruleId > rhs.matchedRule.ruleId
                }
                return lhs.tieBreaker > rhs.tieBreaker
            }
            return lhs.matchScore < rhs.matchScore
        } ?? DailyFortuneRenderContext(
            matchedRule: fallbackRule,
            matchScore: 0,
            matchBreakdown: [],
            tieBreaker: 0
        )
    }

    private static func ruleBreakdown(
        _ rule: DailyGuidanceKnowledge,
        insight: FortuneDailyInsight
    ) -> [FortuneScoreComponent] {
        let supportText = insight.supportReasons.joined(separator: " ")
        let riskText = insight.riskReasons.joined(separator: " ")
        let yiSet = Set(insight.yiTags)
        let elementScore = rule.primaryElement == insight.dayElement ? 6 : 0
        let levelScore = rule.favorableLevels.contains(insight.favorableLevel) ? 4 : 0
        let supportScore = overlapScore(keywords: rule.supportKeywords, text: supportText)
        let riskScore = overlapScore(keywords: rule.riskKeywords, text: riskText)
        let sceneScore = rule.adviceScenes.reduce(0) { partialResult, scene in
            partialResult + (yiSet.contains(scene) ? 2 : 0)
        }

        return [
            FortuneScoreComponent(
                key: "rule-element",
                label: "主五行匹配",
                score: elementScore,
                reason: elementScore > 0
                    ? "知识规则主五行\(rule.primaryElement)与流日主气一致。"
                    : "知识规则主五行\(rule.primaryElement)与流日主气不一致。"
            ),
            FortuneScoreComponent(
                key: "rule-level",
                label: "吉凶层级匹配",
                score: levelScore,
                reason: levelScore > 0
                    ? "知识规则接受当前\(insight.favorableLevel)位节律。"
                    : "知识规则更适合其他节律层级。"
            ),
            FortuneScoreComponent(
                key: "rule-support-keywords",
                label: "助力关键词",
                score: supportScore,
                reason: "支持信号与知识关键词命中的累计分为\(supportScore)。"
            ),
            FortuneScoreComponent(
                key: "rule-risk-keywords",
                label: "风险关键词",
                score: riskScore,
                reason: "风险信号与知识关键词命中的累计分为\(riskScore)。"
            ),
            FortuneScoreComponent(
                key: "rule-scenes",
                label: "场景贴合",
                score: sceneScore,
                reason: "宜做事项与知识规则建议场景的贴合分为\(sceneScore)。"
            )
        ]
    }

    private static func overlapScore(keywords: [String], text: String) -> Int {
        keywords.reduce(0) { partialResult, keyword in
            partialResult + (text.contains(keyword) ? 2 : 0)
        }
    }

    private static func tieBreakSeed(for insight: FortuneDailyInsight) -> String {
        [
            insight.calendar.yearPillar.label,
            insight.calendar.monthPillar.label,
            insight.calendar.dayPillar.label,
            insight.natalDayMasterElement,
            insight.natalStrengthLabel,
            insight.natalPattern,
            insight.favorableLevel
        ].joined(separator: "|")
    }

    private static func stableHash(_ value: String) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return hash
    }
}

struct LocalDailyFortuneService: DailyFortuneServicing {
    private let repository: any FortuneLocalRepositorying

    init(repository: any FortuneLocalRepositorying = SwiftDataFortuneRepository.shared) {
        self.repository = repository
    }

    func fetchDailyFortune(for profile: ProfileSnapshot, on date: Date) async throws -> DailyFortunePayload {
        let knowledge = try await repository.loadDailyKnowledge()
        guard !knowledge.isEmpty else {
            throw DailyFortuneServiceError.serviceUnavailable
        }
        let insight = try FortuneAlgorithmEngine.analyzeDaily(
            for: FortuneBirthInput(
                birthDate: profile.birthDate,
                birthHourLabel: profile.birthHourLabel,
                gender: profile.gender,
                calendarType: profile.calendarType,
                isLeapMonth: profile.isLeapMonth
            ),
            targetDate: date
        )
        let renderContext = DailyFortuneRenderContext.resolve(insight: insight, knowledge: knowledge)
        let rule = renderContext.matchedRule
        let seed = Self.dailySeed(for: profile, insight: insight)
        let recommendedItems = mergedGuidance(
            primary: insight.yiTags,
            fallback: rule.recommendations,
            seed: seed + "|yi"
        )
        let cautionItems = mergedGuidance(
            primary: insight.jiTags,
            fallback: rule.cautions,
            seed: seed + "|ji"
        )

        return DailyFortunePayload(
            heroTitle: insight.headline,
            heroSubtitle: Self.heroSubtitle(
                for: profile,
                rule: rule,
                summary: insight.summary,
                insight: insight,
                recommendedItems: recommendedItems,
                cautionItems: cautionItems,
                seed: seed
            ),
            ganzhiLabel: "今日干支",
            ganzhiValue: insight.calendar.dayPillar.label + " · " + Self.rhythmLine(for: profile, rule: rule),
            updateHint: Self.updateHint(for: date),
            recommendedLine: "宜：\(recommendedItems.joined(separator: "、"))",
            cautionLine: "忌：\(cautionItems.joined(separator: "、"))",
            oracleTitle: "今日签语",
            oraclePreview: Self.oraclePreview(rule: rule, insight: insight, seed: seed),
            oracleDetail: Self.oracleDetail(
                rule: rule,
                insight: insight,
                recommendedItems: recommendedItems,
                cautionItems: cautionItems,
                seed: seed
            )
        )
    }

    private static func heroSubtitle(
        for profile: ProfileSnapshot,
        rule: DailyGuidanceKnowledge,
        summary: String,
        insight: FortuneDailyInsight,
        recommendedItems: [String],
        cautionItems: [String],
        seed: String
    ) -> String {
        let theme = dailyTheme(for: insight)
        let action = recommendedItems.first ?? "稳步推进"
        let caution = cautionItems.first ?? "仓促决策"
        let themeLine = rankedSelection(
            [
                "\(theme)会更容易成为今天的主轴，适合围绕“\(action)”来安排轻重。",
                "今天更容易把注意力落到\(theme)上，先抓住“\(action)”会比四处分心更顺。",
                "今日重心偏向\(theme)，把“\(action)”排到前面，会比急着全面铺开更合拍。"
            ],
            seed: seed + "|hero-theme"
        ).first ?? "\(theme)会更容易成为今天的主轴。"
        let riskLine = rankedSelection(
            [
                "若被“\(caution)”带偏，整体就容易从顺势变成内耗。",
                "今天不太适合被“\(caution)”牵着走，先稳住节奏会更有空间。",
                "只要避开“\(caution)”这类动作，今天的起伏通常还能控在手里。"
            ],
            seed: seed + "|hero-risk"
        ).first ?? ""
        let regulationLine = insight.natalSeasonalAdjustmentElements.isEmpty
            ? ""
            : "命局调候上可参考\(insight.natalSeasonalAdjustmentElements.joined(separator: "、"))之势。"

        return "结合\(profile.calendarType)档案与\(profile.birthHourLabel)整理的今日参考。\(summary) \(insight.natalStrengthSummary) \(themeLine) \(rule.heroSubtitle) \(regulationLine) \(riskLine)"
    }

    private static func rhythmLine(for profile: ProfileSnapshot, rule: DailyGuidanceKnowledge) -> String {
        let hourFocus = profile.birthHourLabel.components(separatedBy: " ").first ?? profile.birthHourLabel
        return "\(rule.rhythmDescriptor) · \(profile.gender)命 · \(hourFocus)"
    }

    private static func updateHint(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM-dd"
        return "\(formatter.string(from: date)) 参考"
    }

    private static func oraclePreview(
        rule: DailyGuidanceKnowledge,
        insight: FortuneDailyInsight,
        seed: String
    ) -> String {
        let theme = dailyTheme(for: insight)
        let lead = rankedSelection(
            [
                rule.oracleHead,
                oracleLeadLine(for: insight),
                "流日\(insight.calendar.dayPillar.label)映照\(insight.natalPattern)，今日更适合把重点落在\(theme)。",
                "今日主气偏向\(theme)，若顺着\(insight.natalFavorableElements.joined(separator: "、"))去安排，起伏会更可控。",
                insight.natalSeasonalAdjustmentElements.isEmpty
                    ? nil
                    : "从命局调候看，今天也适合顺着\(insight.natalSeasonalAdjustmentElements.joined(separator: "、"))的方向做取舍。"
            ].compactMap { $0 },
            seed: seed + "|preview-lead"
        ).first ?? rule.oracleHead
        let focus = rankedSelection(
            [
                insight.supportReasons.first,
                insight.riskReasons.first.map { "也要记得避开：\($0)" },
                "宜先照看\(insight.natalDayMasterElement)日主的节律，再决定是否扩大安排。",
                "今天不是不能发力，而是更适合先把\(theme)理顺。"
            ].compactMap { $0 },
            seed: seed + "|preview-focus"
        ).first ?? insight.summary

        return "签曰：\(lead) \(focus)"
    }

    private static func oracleDetail(
        rule: DailyGuidanceKnowledge,
        insight: FortuneDailyInsight,
        recommendedItems: [String],
        cautionItems: [String],
        seed: String
    ) -> OracleDetailPayload {
        let supportText = rankedSelection(
            insight.supportReasons.isEmpty
                ? [
                    "当前更宜持重行事，先稳住既定安排。",
                    "今日没有明显额外助推，更适合把步子走稳。",
                    "今天更像是调整重心的一天，不必急着样样都上。"
                ]
                : insight.supportReasons,
            seed: seed + "|detail-support"
        ).prefix(2).joined(separator: "；")
        let riskText = rankedSelection(
            insight.riskReasons.isEmpty
                ? [
                    "今日整体无明显强冲，仍需保持节律。",
                    "虽然没有重风险信号，也不宜把安排一下铺得过满。",
                    "风险更多来自自己用力过头，而不是外部硬冲。"
                ]
                : insight.riskReasons,
            seed: seed + "|detail-risk"
        ).prefix(2).joined(separator: "；")
        let focusAction = recommendedItems.first ?? rule.adviceKeyword
        let holdAction = cautionItems.first ?? "仓促决策"
        let theme = dailyTheme(for: insight)
        let bodyLead = rankedSelection(
            [
                rule.oracleBody,
                "今日解签重点落在\(insight.natalPattern)与流日\(insight.calendar.dayPillar.label)的呼应上，重点不在求快，而在看清\(theme)的轻重。",
                "今日更适合顺着\(insight.natalDayMasterElement)日主的节律行事，先把确定的事情做实。",
                "今天更像是围绕\(theme)做取舍的一天，先定主轴，再决定哪里该推、哪里该收。",
                insight.natalSeasonalAdjustmentElements.isEmpty
                    ? nil
                    : "命局调候更看\(insight.natalSeasonalAdjustmentElements.joined(separator: "、"))，所以今天不宜只看快慢，更要看有没有顺着自己的节律。"
            ].compactMap { $0 },
            seed: seed + "|detail-body"
        ).first ?? rule.oracleBody

        return OracleDetailPayload(
            title: "今日解签",
            category: "\(rule.oracleCategory) · \(oracleTone(for: insight))",
            body: "\(bodyLead) \(supportText) \(riskText)",
            adviceTitle: "解签提示",
            adviceBody: rankedSelection(
                [
                    "优先做“\(focusAction)”这一类事，再决定是否扩张计划；对“\(holdAction)”暂缓一步，会更稳。若顺着\(insight.natalFavorableElements.joined(separator: "、"))之势推进，整体更容易回到自己的节奏。",
                    "今天更适合把资源先投到“\(focusAction)”上，而不是被“\(holdAction)”牵走注意力；这样更容易把\(theme)做实。",
                    "若今天只能抓一件重点，就先抓“\(focusAction)”；把“\(holdAction)”往后放，反而更容易看到真正的助力落点。"
                ],
                seed: seed + "|detail-advice"
            ).first ?? "优先做“\(focusAction)”这一类事，再决定是否扩张计划。",
            triggerHint: "内容会随已保存命盘与当天干支一起变化，同一人每天的侧重点会不同",
            secondaryButtonTitle: "稍后再看",
            primaryButtonTitle: "收下今日提醒"
        )
    }

    private func mergedGuidance(primary: [String], fallback: [String], seed: String) -> [String] {
        let primaryRanked = Self.rankedSelection(primary, seed: seed + "|primary")
        let fallbackRanked = Self.rankedSelection(fallback, seed: seed + "|fallback")
        var merged: [String] = []

        for item in primaryRanked.prefix(2) where !merged.contains(item) {
            merged.append(item)
        }
        for item in fallbackRanked.prefix(2) where !merged.contains(item) {
            merged.append(item)
        }
        for item in primaryRanked.dropFirst(2) where !merged.contains(item) {
            merged.append(item)
        }
        for item in fallbackRanked.dropFirst(2) where !merged.contains(item) {
            merged.append(item)
        }

        return Array(merged.prefix(3))
    }

    private static func dailySeed(for profile: ProfileSnapshot, insight: FortuneDailyInsight) -> String {
        [
            profile.profileId,
            profile.birthDate,
            profile.birthHourLabel,
            profile.gender,
            profile.calendarType,
            insight.calendar.yearPillar.label,
            insight.calendar.monthPillar.label,
            insight.calendar.dayPillar.label,
            insight.natalPattern,
            insight.natalStrengthLabel
        ].joined(separator: "|")
    }

    private static func oracleLeadLine(for insight: FortuneDailyInsight) -> String {
        switch insight.dayElement {
        case "木":
            return insight.favorableLevel == "高" ? "木气舒展，今日更像生发与铺开的时段。" : "木气轻动，今天要先定方向，再谈扩展。"
        case "火":
            return insight.favorableLevel == "高" ? "火意见明，今天更偏表达、推进与亮相。" : "火势偏动，今日开口之前先分轻重。"
        case "土":
            return insight.favorableLevel == "高" ? "土厚可载，今天偏现实、承接与落地。" : "土气守中，今天更适合把现实安排先安稳。"
        case "金":
            return insight.favorableLevel == "高" ? "金气清整，今天更适合定规则、理边界、做决断。" : "金风渐紧，今天先收束再判断，会比硬推更稳。"
        case "水":
            return insight.favorableLevel == "高" ? "水意回润，今天偏信息流动、观察与回收。" : "水波微动，今天先沉心看清，再决定往哪边走。"
        default:
            return ruleFallbackLead(for: insight.favorableLevel)
        }
    }

    private static func ruleFallbackLead(for favorableLevel: String) -> String {
        switch favorableLevel {
        case "高":
            return "气势相扶，宜顺势而行。"
        case "中上":
            return "节律渐起，宜稳中求进。"
        case "平":
            return "气机守中，宜先收后放。"
        default:
            return "气势未定，宜先缓一步。"
        }
    }

    private static func oracleTone(for insight: FortuneDailyInsight) -> String {
        let supportCount = insight.supportReasons.count
        let riskCount = insight.riskReasons.count

        if supportCount >= 2 && riskCount == 0 {
            return "顺势位"
        }
        if supportCount >= 2 && riskCount >= 1 {
            return "取舍位"
        }
        if riskCount >= 2 {
            return "收锋位"
        }
        if insight.favorableLevel == "高" || insight.favorableLevel == "中上" {
            return "起势位"
        }
        return "平衡位"
    }

    private static func dailyTheme(for insight: FortuneDailyInsight) -> String {
        if insight.signalHits.contains(where: { $0.key.hasPrefix("daily-branch-harmony") }) {
            return "关系协作与对外往来"
        }
        if insight.signalHits.contains(where: { $0.key.hasPrefix("daily-branch-punish") }) {
            return "尺度统一与边界拿捏"
        }
        if insight.signalHits.contains(where: { $0.key.hasPrefix("daily-branch-harm") }) {
            return "误会澄清与暗耗止损"
        }
        if insight.signalHits.contains(where: { $0.key.hasPrefix("daily-branch-clash") }) {
            return "边界拿捏与情绪收束"
        }
        if insight.signalHits.contains(where: { $0.key == "daily-daymaster-support" || $0.key == "daily-weak-master-support" }) {
            return "推进关键事项与借力承接"
        }
        if insight.signalHits.contains(where: { $0.key == "daily-daymaster-pressure" || $0.key == "daily-daymaster-drain" }) {
            return "节奏调配与精力分配"
        }

        switch insight.dayElement {
        case "木":
            return "拓展计划与学习吸收"
        case "火":
            return "表达亮相与沟通推进"
        case "土":
            return "现实承接与家务事务"
        case "金":
            return "边界规则与决断整理"
        case "水":
            return "信息回收与内在观察"
        default:
            return "日常安排与轻重取舍"
        }
    }

    private static func rankedSelection(_ items: [String], seed: String) -> [String] {
        let uniqueItems = orderedUnique(items)
        return uniqueItems.sorted { lhs, rhs in
            let lhsHash = stableHash(seed + "|" + lhs)
            let rhsHash = stableHash(seed + "|" + rhs)
            if lhsHash == rhsHash {
                return lhs < rhs
            }
            return lhsHash < rhsHash
        }
    }

    private static func orderedUnique(_ items: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for item in items where !item.isEmpty {
            if seen.insert(item).inserted {
                result.append(item)
            }
        }
        return result
    }

    private static func stableHash(_ value: String) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return hash
    }
}

enum DailyFortuneServiceError: Error, LocalizedError, Equatable, Sendable {
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            "今日参考暂未成功生成，请稍后再试。"
        }
    }
}

protocol DailyFortuneServicing: Sendable {
    func fetchDailyFortune(for profile: ProfileSnapshot, on date: Date) async throws -> DailyFortunePayload
}

struct MockDailyFortuneService: DailyFortuneServicing {
    enum Behavior: Sendable {
        case success
        case failure(DailyFortuneServiceError)
    }

    let behavior: Behavior

    init(behavior: Behavior = .success) {
        self.behavior = behavior
    }

    func fetchDailyFortune(for profile: ProfileSnapshot, on date: Date) async throws -> DailyFortunePayload {
        try await Task.sleep(nanoseconds: 180_000_000)

        switch behavior {
        case .success:
            return DailyFortunePayload.sample(for: profile, on: date)
        case .failure(let error):
            throw error
        }
    }
}
