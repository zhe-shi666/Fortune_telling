import Foundation

struct FortuneLocation: Equatable, Sendable {
    var longitude: Double
    var latitude: Double

    static let shanghai = FortuneLocation(longitude: 121.4737, latitude: 31.2304)
}

struct FortuneBirthInput: Equatable, Sendable {
    var birthDate: String
    var birthHourLabel: String
    var gender: String
    var calendarType: String
    var isLeapMonth: Bool
    var location: FortuneLocation
    var timezone: TimeZone

    init(
        birthDate: String,
        birthHourLabel: String,
        gender: String,
        calendarType: String,
        isLeapMonth: Bool = false,
        location: FortuneLocation = .shanghai,
        timezone: TimeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
    ) {
        self.birthDate = birthDate
        self.birthHourLabel = birthHourLabel
        self.gender = gender
        self.calendarType = calendarType
        self.isLeapMonth = isLeapMonth
        self.location = location
        self.timezone = timezone
    }
}

struct FortunePillar: Equatable, Sendable {
    var stem: String
    var branch: String

    var label: String {
        stem + branch
    }
}

struct FortuneSolarTermContext: Equatable, Sendable {
    var currentJieName: String
    var currentJieIndex: Int
    var currentJieDate: Date
    var nextJieName: String
    var nextJieDate: Date
}

struct FortuneCalendarSnapshot: Equatable, Sendable {
    var localDate: Date
    var trueSolarDate: Date
    var equationOfTimeMinutes: Double
    var localLongitudeOffsetMinutes: Double
    var solarTerm: FortuneSolarTermContext
    var yearPillar: FortunePillar
    var monthPillar: FortunePillar
    var dayPillar: FortunePillar
    var hourPillar: FortunePillar
}

struct FortuneTenGodSummary: Equatable, Sendable {
    var label: String
    var count: Int
}

struct FortuneBaziAnalysis: Equatable, Sendable {
    var calendar: FortuneCalendarSnapshot
    var hiddenStems: [String: [String]]
    var tenGods: [FortuneTenGodSummary]
    var fiveElementScores: [String: Int]
    var dayMasterElement: String
    var dayMasterStrengthLabel: String
    var dayMasterStrengthScore: Int
    var favorableElements: [String]
    var unfavorableElements: [String]
    var seasonalAdjustmentElements: [String]
    var strengthSummary: String
    var resolvedPattern: String
    var interpretation: String
    var scoreBreakdown: [FortuneScoreComponent]
    var patternCandidates: [FortuneScoreComponent]
}

struct FortuneDailyInsight: Equatable, Sendable {
    var calendar: FortuneCalendarSnapshot
    var dayElement: String
    var headline: String
    var summary: String
    var natalDayMasterElement: String
    var natalStrengthLabel: String
    var natalPattern: String
    var natalFavorableElements: [String]
    var natalSeasonalAdjustmentElements: [String]
    var natalStrengthSummary: String
    var yiTags: [String]
    var jiTags: [String]
    var supportReasons: [String]
    var riskReasons: [String]
    var oracleKey: String
    var favorableLevel: String
    var scoreBreakdown: [FortuneScoreComponent]
    var signalHits: [FortuneRuleHit]
}

struct FortuneCompatibilityAnalysis: Equatable, Sendable {
    var score: Int
    var overallBand: String
    var relationTags: [String]
    var focusKeywords: [String]
    var scoreBreakdown: [FortuneScoreComponent]
    var sharedFavorableElements: [String]
    var maleDayMasterElement: String
    var femaleDayMasterElement: String
    var maleStrengthLabel: String
    var femaleStrengthLabel: String
    var dayMasterRelation: String
    var isComplementary: Bool
    var malePattern: String
    var femalePattern: String
    var maleDominantTenGod: String
    var femaleDominantTenGod: String
    var branchSupportDetails: [String]
    var branchConflictDetails: [String]
    var supportMatches: [String]
    var conflictMatches: [String]
    var marriagePalaceRelation: String
}

struct FortuneScoreComponent: Equatable, Sendable {
    var key: String
    var label: String
    var score: Int
    var reason: String
}

struct FortuneRuleHit: Equatable, Sendable {
    var key: String
    var label: String
    var score: Int
    var reason: String
}

struct FortuneNamingCandidate: Equatable, Sendable {
    var title: String
    var totalScore: Int
    var favorableReason: String
    var semanticReason: String
    var rhythmReason: String
    var scoreBreakdown: [FortuneScoreComponent]
}

enum FortuneAlgorithmError: LocalizedError, Equatable, Sendable {
    case invalidInput
    case unsupportedCalendar

    var errorDescription: String? {
        switch self {
        case .invalidInput:
            "出生信息不足，或当前日期与历法组合无效，暂时无法完成历法换算。"
        case .unsupportedCalendar:
            "当前仅支持公历与农历输入。"
        }
    }
}

enum FortuneAlgorithmEngine {
    private struct StrengthContext: Equatable, Sendable {
        var label: String
        var score: Int
        var seasonalAdjustmentElements: [String]
        var summary: String
        var evidence: [FortuneScoreComponent]
    }

    private static let stems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    private static let branches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    private static let fiveElements = ["木", "火", "土", "金", "水"]
    private static let branchMainElements: [String: String] = [
        "子": "水", "丑": "土", "寅": "木", "卯": "木", "辰": "土", "巳": "火",
        "午": "火", "未": "土", "申": "金", "酉": "金", "戌": "土", "亥": "水"
    ]
    private static let hiddenStemMap: [String: [String]] = [
        "子": ["癸"], "丑": ["己", "癸", "辛"], "寅": ["甲", "丙", "戊"], "卯": ["乙"],
        "辰": ["戊", "乙", "癸"], "巳": ["丙", "庚", "戊"], "午": ["丁", "己"], "未": ["己", "丁", "乙"],
        "申": ["庚", "壬", "戊"], "酉": ["辛"], "戌": ["戊", "辛", "丁"], "亥": ["壬", "甲"]
    ]
    private static let stemElementMap: [String: String] = [
        "甲": "木", "乙": "木", "丙": "火", "丁": "火", "戊": "土",
        "己": "土", "庚": "金", "辛": "金", "壬": "水", "癸": "水"
    ]
    private static let tenGodLabels = ["比肩", "劫财", "食神", "伤官", "偏财", "正财", "七杀", "正官", "偏印", "正印"]
    private static let majorSolarTerms: [(name: String, angle: Double)] = [
        ("小寒", 285), ("立春", 315), ("惊蛰", 345), ("清明", 15),
        ("立夏", 45), ("芒种", 75), ("小暑", 105), ("立秋", 135),
        ("白露", 165), ("寒露", 195), ("立冬", 225), ("大雪", 255)
    ]
    private static let majorSolarTermAnchors: [Double: (month: Int, day: Int)] = [
        285: (1, 5), 315: (2, 4), 345: (3, 6), 15: (4, 5),
        45: (5, 5), 75: (6, 6), 105: (7, 7), 135: (8, 7),
        165: (9, 7), 195: (10, 8), 225: (11, 7), 255: (12, 7)
    ]
    private static let monthBranchesByJie = ["丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥", "子"]
    private static let dayStemHourStemStart: [String: Int] = [
        "甲": 0, "己": 0,
        "乙": 2, "庚": 2,
        "丙": 4, "辛": 4,
        "丁": 6, "壬": 6,
        "戊": 8, "癸": 8
    ]
    private static let clashPairs: Set<String> = ["子午", "丑未", "寅申", "卯酉", "辰戌", "巳亥", "午子", "未丑", "申寅", "酉卯", "戌辰", "亥巳"]
    private static let sixHarmonyPairs: Set<String> = ["子丑", "寅亥", "卯戌", "辰酉", "巳申", "午未", "丑子", "亥寅", "戌卯", "酉辰", "申巳", "未午"]
    private static let harmPairs: Set<String> = ["子未", "未子", "丑午", "午丑", "寅巳", "巳寅", "卯辰", "辰卯", "申亥", "亥申", "酉戌", "戌酉"]
    private static let punishmentPairs: Set<String> = [
        "子卯", "卯子",
        "寅巳", "巳寅", "寅申", "申寅", "巳申", "申巳",
        "丑未", "未丑", "丑戌", "戌丑", "未戌", "戌未",
        "辰辰", "午午", "酉酉", "亥亥"
    ]
    private static let punishmentTriples: [[String]] = [
        ["寅", "巳", "申"],
        ["丑", "未", "戌"]
    ]

    static func analyzeBazi(for input: FortuneBirthInput) throws -> FortuneBaziAnalysis {
        let calendar = try resolveCalendar(for: input)
        let hidden = hiddenStems(for: calendar)
        let scores = scoreFiveElements(calendar: calendar)
        let dayMasterStem = calendar.dayPillar.stem
        let dayMasterElement = stemElementMap[dayMasterStem] ?? "土"
        let strengthContext = resolveStrengthContext(
            calendar: calendar,
            scores: scores,
            dayMasterElement: dayMasterElement
        )
        let scoreBreakdown = makeBaziScoreBreakdown(
            calendar: calendar,
            scores: scores,
            dayMasterElement: dayMasterElement,
            strengthContext: strengthContext
        )
        let strengthLabel = strengthContext.label
        let favorable = favorableElements(
            scores: scores,
            dayMasterElement: dayMasterElement,
            strengthLabel: strengthLabel,
            monthBranch: calendar.monthPillar.branch,
            seasonalAdjustmentElements: strengthContext.seasonalAdjustmentElements
        )
        let unfavorable = fiveElements.filter { !favorable.contains($0) }
        let tenGods = resolveTenGods(calendar: calendar)
        let patternResolution = resolvePattern(
            calendar: calendar,
            tenGods: tenGods,
            strengthLabel: strengthLabel
        )
        let interpretation = makeInterpretation(
            dayMasterElement: dayMasterElement,
            strengthLabel: strengthLabel,
            strengthSummary: strengthContext.summary,
            favorable: favorable,
            seasonalAdjustmentElements: strengthContext.seasonalAdjustmentElements,
            pattern: patternResolution.resolvedPattern,
            scoreBreakdown: scoreBreakdown
        )

        return FortuneBaziAnalysis(
            calendar: calendar,
            hiddenStems: hidden,
            tenGods: tenGods,
            fiveElementScores: scores,
            dayMasterElement: dayMasterElement,
            dayMasterStrengthLabel: strengthLabel,
            dayMasterStrengthScore: strengthContext.score,
            favorableElements: favorable,
            unfavorableElements: unfavorable,
            seasonalAdjustmentElements: strengthContext.seasonalAdjustmentElements,
            strengthSummary: strengthContext.summary,
            resolvedPattern: patternResolution.resolvedPattern,
            interpretation: interpretation,
            scoreBreakdown: scoreBreakdown,
            patternCandidates: patternResolution.candidates
        )
    }

    static func analyzeDaily(for input: FortuneBirthInput, targetDate: Date = Date()) throws -> FortuneDailyInsight {
        let birthAnalysis = try analyzeBazi(for: input)
        let dailyInput = FortuneBirthInput(
            birthDate: formatDate(targetDate),
            birthHourLabel: input.birthHourLabel,
            gender: input.gender,
            calendarType: "公历",
            isLeapMonth: false,
            location: input.location,
            timezone: input.timezone
        )
        let calendar = try resolveCalendar(for: dailyInput)
        let dayElement = stemElementMap[calendar.dayPillar.stem] ?? "土"
        let favorable = birthAnalysis.favorableElements
        let natalBranches = [birthAnalysis.calendar.yearPillar.branch, birthAnalysis.calendar.monthPillar.branch, birthAnalysis.calendar.dayPillar.branch, birthAnalysis.calendar.hourPillar.branch]
        let dailyBranch = calendar.dayPillar.branch
        let personalizationSeed = [
            birthAnalysis.calendar.yearPillar.label,
            birthAnalysis.calendar.monthPillar.label,
            birthAnalysis.calendar.dayPillar.label,
            birthAnalysis.calendar.hourPillar.label,
            calendar.dayPillar.label
        ].joined(separator: "|")
        let signalHits = makeDailySignalHits(
            dayElement: dayElement,
            dailyBranch: dailyBranch,
            natalBranches: natalBranches,
            favorable: favorable,
            natalDayMasterElement: birthAnalysis.dayMasterElement,
            natalStrengthLabel: birthAnalysis.dayMasterStrengthLabel
        )
        let supportReasons = signalHits.filter { $0.score > 0 }.map(\.reason)
        let riskReasons = signalHits.filter { $0.score < 0 }.map(\.reason)
        let scoreBreakdown = signalHits.map { hit in
            FortuneScoreComponent(
                key: hit.key,
                label: hit.label,
                score: hit.score,
                reason: hit.reason
            )
        }
        let favorableLevel = resolveDailyLevel(totalScore: scoreBreakdown.reduce(0) { $0 + $1.score })
        let yiTags = makeDailyYiTags(
            signalHits: signalHits,
            favorable: favorable,
            dayElement: dayElement,
            dailyBranch: dailyBranch,
            natalDayMasterElement: birthAnalysis.dayMasterElement,
            natalPattern: birthAnalysis.resolvedPattern,
            natalStrengthLabel: birthAnalysis.dayMasterStrengthLabel,
            seed: personalizationSeed + "|yi"
        )
        let jiTags = makeDailyJiTags(
            signalHits: signalHits,
            favorable: favorable,
            dayElement: dayElement,
            dailyBranch: dailyBranch,
            natalDayMasterElement: birthAnalysis.dayMasterElement,
            natalPattern: birthAnalysis.resolvedPattern,
            natalStrengthLabel: birthAnalysis.dayMasterStrengthLabel,
            seed: personalizationSeed + "|ji"
        )
        let oracleKey = "\(favorableLevel)-\(dayElement)-\(dailyBranch)"
        let summary = "流日\(calendar.dayPillar.label)与命局\(birthAnalysis.dayMasterElement)日主相映，当前更偏向\(favorableLevel)参考。"

        return FortuneDailyInsight(
            calendar: calendar,
            dayElement: dayElement,
            headline: "黄历今朝",
            summary: summary,
            natalDayMasterElement: birthAnalysis.dayMasterElement,
            natalStrengthLabel: birthAnalysis.dayMasterStrengthLabel,
            natalPattern: birthAnalysis.resolvedPattern,
            natalFavorableElements: favorable,
            natalSeasonalAdjustmentElements: birthAnalysis.seasonalAdjustmentElements,
            natalStrengthSummary: birthAnalysis.strengthSummary,
            yiTags: yiTags,
            jiTags: jiTags,
            supportReasons: supportReasons,
            riskReasons: riskReasons,
            oracleKey: oracleKey,
            favorableLevel: favorableLevel,
            scoreBreakdown: scoreBreakdown,
            signalHits: signalHits
        )
    }

    static func analyzeCompatibility(male: FortuneBirthInput, female: FortuneBirthInput) throws -> FortuneCompatibilityAnalysis {
        let maleAnalysis = try analyzeBazi(for: male)
        let femaleAnalysis = try analyzeBazi(for: female)

        var score = 68
        var support: [String] = []
        var conflicts: [String] = []
        var scoreBreakdown: [FortuneScoreComponent] = [
            FortuneScoreComponent(
                key: "base",
                label: "基础分",
                score: 68,
                reason: "以中性命盘匹配作为起点，再按喜用、夫妻宫、地支互动与格局结构做加减分。"
            )
        ]

        let favorableIntersection = Set(maleAnalysis.favorableElements).intersection(femaleAnalysis.favorableElements)
        let favorableScore = favorableIntersection.count * 8
        score += favorableScore
        scoreBreakdown.append(
            FortuneScoreComponent(
                key: "favorable-intersection",
                label: "喜用契合",
                score: favorableScore,
                reason: favorableIntersection.isEmpty
                    ? "双方暂未形成明显共通喜用，主要靠其他结构因素补充判断。"
                    : "双方共通喜用落在\(favorableIntersection.sorted().joined(separator: "、"))，有助于形成一致的发力方向。"
            )
        )
        if !favorableIntersection.isEmpty {
            support.append("双方喜用方向存在交集：\(favorableIntersection.sorted().joined(separator: "、"))")
        }

        let complementary = Set(maleAnalysis.favorableElements).intersection(Set(femaleAnalysis.unfavorableElements)).isEmpty
            && Set(femaleAnalysis.favorableElements).intersection(Set(maleAnalysis.unfavorableElements)).isEmpty
        if complementary {
            score += 8
            scoreBreakdown.append(
                FortuneScoreComponent(
                    key: "favorable-complement",
                    label: "喜忌互补",
                    score: 8,
                    reason: "双方喜忌没有明显对撞，日常推进更容易形成互补节律。"
                )
            )
            support.append("双方喜忌不明显相冲，整体更容易形成互补节律")
        } else {
            score -= 6
            scoreBreakdown.append(
                FortuneScoreComponent(
                    key: "favorable-conflict",
                    label: "喜忌错位",
                    score: -6,
                    reason: "双方喜用与对方忌向出现错位，相处中更需要先约定边界和节奏。"
                )
            )
            conflicts.append("双方喜忌存在错位，日常相处更需要先定边界")
        }

        let palaceRelation = relationshipLabel(
            lhs: maleAnalysis.calendar.dayPillar.branch,
            rhs: femaleAnalysis.calendar.dayPillar.branch
        )
        switch palaceRelation {
        case "六合":
            score += 10
            scoreBreakdown.append(
                FortuneScoreComponent(
                    key: "marriage-palace",
                    label: "夫妻宫关系",
                    score: 10,
                    reason: "双方夫妻宫形成六合，更容易先建立默契和信任。"
                )
            )
            support.append("夫妻宫形成六合，彼此更容易建立默契")
        case "相冲":
            score -= 12
            scoreBreakdown.append(
                FortuneScoreComponent(
                    key: "marriage-palace",
                    label: "夫妻宫关系",
                    score: -12,
                    reason: "双方夫妻宫相冲，现实节奏与情绪表达更容易出现拉扯。"
                )
            )
            conflicts.append("夫妻宫存在相冲，情绪与节奏差异需要更多经营")
        case "相害":
            score -= 8
            scoreBreakdown.append(
                FortuneScoreComponent(
                    key: "marriage-palace",
                    label: "夫妻宫关系",
                    score: -8,
                    reason: "双方夫妻宫相害，关系里更容易累积细碎误解与暗耗。"
                )
            )
            conflicts.append("夫妻宫存在相害，细碎摩擦更容易消耗默契")
        case "相刑":
            score -= 10
            scoreBreakdown.append(
                FortuneScoreComponent(
                    key: "marriage-palace",
                    label: "夫妻宫关系",
                    score: -10,
                    reason: "双方夫妻宫相刑，关系里更容易因立场僵持或分寸失衡出现消耗。"
                )
            )
            conflicts.append("夫妻宫存在相刑，遇事更容易卡在立场与分寸上")
        default:
            scoreBreakdown.append(
                FortuneScoreComponent(
                    key: "marriage-palace",
                    label: "夫妻宫关系",
                    score: 0,
                    reason: "夫妻宫没有强烈冲合，更多要看其他结构与日常经营。"
                )
            )
            support.append("夫妻宫暂无明显强冲，适合从现实协作慢慢建立稳定感")
        }

        let dayMasterRelation = elementRelationship(
            from: maleAnalysis.dayMasterElement,
            to: femaleAnalysis.dayMasterElement
        )
        switch dayMasterRelation {
        case "相生":
            score += 6
            scoreBreakdown.append(
                FortuneScoreComponent(
                    key: "day-master",
                    label: "日主关系",
                    score: 6,
                    reason: "双方日主形成相生，更容易在互动中彼此提供支持。"
                )
            )
            support.append("双方日主五行形成相生，彼此更容易提供支持")
        case "相克":
            score -= 6
            scoreBreakdown.append(
                FortuneScoreComponent(
                    key: "day-master",
                    label: "日主关系",
                    score: -6,
                    reason: "双方日主存在相克，沟通方式更需要控制锋芒与步调。"
                )
            )
            conflicts.append("双方日主五行存在相克，沟通上更要注意节制与让步")
        default:
            scoreBreakdown.append(
                FortuneScoreComponent(
                    key: "day-master",
                    label: "日主关系",
                    score: 0,
                    reason: "双方日主同气或相对平衡，关系推进更依赖现实协作。"
                )
            )
            break
        }

        let strengthGap = strengthRank(maleAnalysis.dayMasterStrengthLabel) - strengthRank(femaleAnalysis.dayMasterStrengthLabel)
        if abs(strengthGap) <= 1 {
            score += 5
            scoreBreakdown.append(
                FortuneScoreComponent(
                    key: "strength-balance",
                    label: "强弱平衡",
                    score: 5,
                    reason: "双方命局强弱差距不大，更容易保持均衡互动。"
                )
            )
            support.append("双方命局强弱差距不大，相处时更容易保持平衡")
        } else {
            score -= 3
            scoreBreakdown.append(
                FortuneScoreComponent(
                    key: "strength-balance",
                    label: "强弱平衡",
                    score: -3,
                    reason: "双方命局强弱差距较大，关系里更容易出现一方过度主导。"
                )
            )
            conflicts.append("双方命局强弱差距较大，容易一方过度主导")
        }

        let branchInteraction = branchInteractionSummary(
            lhs: maleAnalysis.calendar,
            rhs: femaleAnalysis.calendar
        )
        score += branchInteraction.scoreAdjustment
        scoreBreakdown.append(
            FortuneScoreComponent(
                key: "branch-interaction",
                label: "地支互动",
                score: branchInteraction.scoreAdjustment,
                reason: branchInteraction.conflictDetails.first
                    ?? branchInteraction.supportDetails.first
                    ?? "四柱支位之间暂未见特别强的同频或冲突信号。"
            )
        )
        support.append(contentsOf: branchInteraction.supportDetails.prefix(2))
        conflicts.append(contentsOf: branchInteraction.conflictDetails.prefix(2))

        let patternInteraction = patternInteractionSummary(
            maleAnalysis: maleAnalysis,
            femaleAnalysis: femaleAnalysis
        )
        score += patternInteraction.scoreAdjustment
        scoreBreakdown.append(
            FortuneScoreComponent(
                key: "pattern-interaction",
                label: "格局互动",
                score: patternInteraction.scoreAdjustment,
                reason: patternInteraction.conflictLine
                    ?? patternInteraction.supportLine
                    ?? "双方格局与十神重心未形成明显放大或削弱因素。"
            )
        )
        if let supportLine = patternInteraction.supportLine {
            support.append(supportLine)
        }
        if let conflictLine = patternInteraction.conflictLine {
            conflicts.append(conflictLine)
        }

        let rawScore = score
        score = min(max(score, 55), 96)
        if score != rawScore {
            scoreBreakdown.append(
                FortuneScoreComponent(
                    key: "score-calibration",
                    label: "分值校正",
                    score: score - rawScore,
                    reason: "为保持娱乐参考分值区间稳定，结果会收敛到 55 到 96 之间。"
                )
            )
        }
        let band = score >= 85 ? "高契合" : (score >= 74 ? "稳步磨合" : "需要经营")
        let relationTags = compatibilityRelationTags(
            palaceRelation: palaceRelation,
            dayMasterRelation: dayMasterRelation,
            score: score,
            complementary: complementary,
            conflicts: conflicts
        )
        let focusKeywords = compatibilityFocusKeywords(
            support: support,
            conflicts: conflicts,
            score: score
        )

        return FortuneCompatibilityAnalysis(
            score: score,
            overallBand: band,
            relationTags: relationTags,
            focusKeywords: focusKeywords,
            scoreBreakdown: scoreBreakdown,
            sharedFavorableElements: favorableIntersection.sorted(),
            maleDayMasterElement: maleAnalysis.dayMasterElement,
            femaleDayMasterElement: femaleAnalysis.dayMasterElement,
            maleStrengthLabel: maleAnalysis.dayMasterStrengthLabel,
            femaleStrengthLabel: femaleAnalysis.dayMasterStrengthLabel,
            dayMasterRelation: dayMasterRelation,
            isComplementary: complementary,
            malePattern: maleAnalysis.resolvedPattern,
            femalePattern: femaleAnalysis.resolvedPattern,
            maleDominantTenGod: dominantTenGodLabel(from: maleAnalysis.tenGods),
            femaleDominantTenGod: dominantTenGodLabel(from: femaleAnalysis.tenGods),
            branchSupportDetails: branchInteraction.supportDetails,
            branchConflictDetails: branchInteraction.conflictDetails,
            supportMatches: Array(support.prefix(3)),
            conflictMatches: Array(conflicts.prefix(2)),
            marriagePalaceRelation: palaceRelation
        )
    }

    static func recommendNames(
        for input: FortuneBirthInput,
        surname: String?,
        lexicon: NamingLexiconKnowledge,
        limit: Int = 8
    ) throws -> [FortuneNamingCandidate] {
        let analysis = try analyzeBazi(for: input)
        guard !lexicon.surnames.isEmpty, !lexicon.givenNames.isEmpty else {
            return []
        }

        let resolvedSurname = normalizedSurname(surname) ?? lexicon.surnames.first ?? "林"
        let favorable = Set(analysis.favorableElements)
        let supportElements = Set(analysis.favorableElements + [analysis.dayMasterElement])
        let dayMasterStrength = strengthRank(analysis.dayMasterStrengthLabel)
        let surnameEntry = lexicon.surnameEntries.first(where: { $0.value == resolvedSurname })
        let surnameTags = Set(surnameEntry?.styleTags ?? [])

        let scored = lexicon.givenNames.enumerated().map { index, givenName -> (candidate: FortuneNamingCandidate, alignmentTier: Int) in
            let fullName = resolvedSurname + givenName.leading + givenName.trailing
            let rhythmBonus = rhythmScore(for: fullName)
            let semanticBonus = semanticScore(for: givenName)
            let genderAlignment = genderAlignment(for: givenName, targetGender: input.gender)
            let styleBonus = styleCompatibilityScore(
                surnameTags: surnameTags,
                semanticTags: Set(givenName.semanticTags),
                styleLabel: givenName.styleLabel
            )
            let mainElementScore = favorable.contains(givenName.element)
                ? 12
                : (supportElements.contains(givenName.element) ? 7 : 2)
            let supportElementScore = favorable.contains(givenName.supportElement)
                ? 10
                : (supportElements.contains(givenName.supportElement) ? 5 : 1)
            let pairHarmonyBonus = elementRelationship(
                from: givenName.element,
                to: givenName.supportElement
            ) == "相生" ? 5 : 1
            let compositionBonus = givenName.leading == givenName.trailing ? -3 : 2
            let commonnessScore = commonnessScore(for: givenName.commonnessRank)
            let complexityPenalty = writingComplexityPenalty(for: givenName.writingComplexity)
            let lexiconWeightScore = givenName.weight / 6
            let rankPenalty = index
            let strengthAdjustment = dayMasterStrength >= 3
                ? (givenName.element == analysis.dayMasterElement ? -4 : 0)
                : (favorable.contains(givenName.element) ? 3 : 0)

            let rawScore = 46
                + mainElementScore
                + supportElementScore
                + pairHarmonyBonus
                + rhythmBonus
                + semanticBonus
                + styleBonus
                + commonnessScore
                + lexiconWeightScore
                + genderAlignment.scoreAdjustment
                + compositionBonus
                + strengthAdjustment
                - complexityPenalty
                - rankPenalty
            let boundedScore = min(max(rawScore, 68), 98)
            var scoreBreakdown = [
                FortuneScoreComponent(
                    key: "base",
                    label: "基础分",
                    score: 46,
                    reason: "以基础可读性与候选成立性作为起点，再叠加命理、语义、音律与书写等维度。"
                ),
                FortuneScoreComponent(
                    key: "main-element",
                    label: "主五行贴合",
                    score: mainElementScore,
                    reason: favorable.contains(givenName.element)
                        ? "名字主字五行\(givenName.element)直接贴合当前喜用方向。"
                        : "名字主字五行\(givenName.element)更多承担辅助平衡作用。"
                ),
                FortuneScoreComponent(
                    key: "support-element",
                    label: "辅五行贴合",
                    score: supportElementScore,
                    reason: favorable.contains(givenName.supportElement)
                        ? "名字辅字五行\(givenName.supportElement)同样落在当前喜用范围。"
                        : "名字辅字五行\(givenName.supportElement)用于补足整体层次。"
                ),
                FortuneScoreComponent(
                    key: "element-harmony",
                    label: "字内生克",
                    score: pairHarmonyBonus,
                    reason: elementRelationship(from: givenName.element, to: givenName.supportElement) == "相生"
                        ? "双字五行之间形成相生，名字内部气口更顺。"
                        : "双字五行未形成明显相生，因此只保留基础分。"
                ),
                FortuneScoreComponent(
                    key: "rhythm",
                    label: "音律节奏",
                    score: rhythmBonus,
                    reason: "姓名整体读感节奏得分为\(rhythmBonus)，用于区分叫读顺口度。"
                ),
                FortuneScoreComponent(
                    key: "semantic",
                    label: "字义气质",
                    score: semanticBonus,
                    reason: "名字语义重心落在\(givenName.semanticTags.prefix(2).joined(separator: "、"))，气质偏\(givenName.mood)。"
                ),
                FortuneScoreComponent(
                    key: "style",
                    label: "风格协调",
                    score: styleBonus,
                    reason: "姓氏风格与名字标签的协调分为\(styleBonus)，风格标签偏\(givenName.styleLabel)。"
                ),
                FortuneScoreComponent(
                    key: "gender-alignment",
                    label: "性别匹配",
                    score: genderAlignment.scoreAdjustment,
                    reason: genderAlignment.reason
                ),
                FortuneScoreComponent(
                    key: "commonness",
                    label: "常见度",
                    score: commonnessScore,
                    reason: "常见度排名\(givenName.commonnessRank)，用于平衡审美熟悉度与辨识度。"
                ),
                FortuneScoreComponent(
                    key: "lexicon-weight",
                    label: "词库权重",
                    score: lexiconWeightScore,
                    reason: "词库权重为\(givenName.weight)，作为基础偏好加权。"
                ),
                FortuneScoreComponent(
                    key: "composition",
                    label: "字形组合",
                    score: compositionBonus,
                    reason: compositionBonus > 0
                        ? "双字组合避免重复字形，视觉上更舒展。"
                        : "双字重复度较高，因此下调组合分。"
                ),
                FortuneScoreComponent(
                    key: "strength-adjustment",
                    label: "强弱校正",
                    score: strengthAdjustment,
                    reason: strengthAdjustment >= 0
                        ? "根据日主强弱，对喜用方向做了额外扶助。"
                        : "考虑到日主已不弱，减少同类五行的继续堆叠。"
                ),
                FortuneScoreComponent(
                    key: "complexity",
                    label: "书写复杂度",
                    score: -complexityPenalty,
                    reason: "书写复杂度为\(givenName.writingComplexity)，用于控制日常书写负担。"
                ),
                FortuneScoreComponent(
                    key: "rank-penalty",
                    label: "排序去重",
                    score: -rankPenalty,
                    reason: "为避免前部词条长期垄断推荐位，对词库顺位做轻度去重。"
                )
            ]
            let calibrationScore = boundedScore - rawScore
            if calibrationScore != 0 {
                scoreBreakdown.append(
                    FortuneScoreComponent(
                        key: "score-calibration",
                        label: "分值校正",
                        score: calibrationScore,
                        reason: "为保持娱乐参考分值区间稳定，结果会收敛到 68 到 98 之间。"
                    )
                )
            }
            let semanticText = givenName.semanticTags.isEmpty
                ? givenName.styleLabel
                : givenName.semanticTags.prefix(2).joined(separator: "、")

            return (
                candidate: FortuneNamingCandidate(
                    title: fullName,
                    totalScore: boundedScore,
                    favorableReason: "命局当前更喜\(analysis.favorableElements.joined(separator: "、"))，此名偏向\(givenName.element)\(givenName.supportElement)之气。",
                    semanticReason: "字义气质偏\(givenName.mood)，语义重心在\(semanticText)，\(genderAlignment.reason)。",
                    rhythmReason: "姓名读感节奏\(rhythmBonus >= 6 ? "顺" : "稳")，风格偏\(givenName.styleLabel)，适合日常称呼与书写。",
                    scoreBreakdown: scoreBreakdown
                ),
                alignmentTier: genderAlignment.tier
            )
        }

        return Array(scored.sorted { lhs, rhs in
            if lhs.alignmentTier != rhs.alignmentTier {
                return lhs.alignmentTier > rhs.alignmentTier
            }
            if lhs.candidate.totalScore != rhs.candidate.totalScore {
                return lhs.candidate.totalScore > rhs.candidate.totalScore
            }
            return lhs.candidate.title < rhs.candidate.title
        }.map(\.candidate).prefix(limit))
    }

    private static func resolveCalendar(for input: FortuneBirthInput) throws -> FortuneCalendarSnapshot {
        guard input.calendarType == "公历" || input.calendarType == "农历" else {
            throw FortuneAlgorithmError.unsupportedCalendar
        }
        let localDate = try resolvedSourceDate(for: input)

        let nominalHour = nominalHour(for: input.birthHourLabel)
        let localDateTime = merge(date: localDate, hour: nominalHour, timezone: input.timezone)
        let equationOfTime = equationOfTimeMinutes(for: localDateTime)
        let longitudeOffset = (input.location.longitude - 120.0) * 4.0
        let trueSolarDate = localDateTime.addingTimeInterval((equationOfTime + longitudeOffset) * 60)

        let liChun = solarTermMoment(forYear: calendarYear(for: trueSolarDate, timezone: input.timezone), angle: 315, timezone: input.timezone)
        let adjustedYear = trueSolarDate >= liChun ? calendarYear(for: trueSolarDate, timezone: input.timezone) : calendarYear(for: trueSolarDate, timezone: input.timezone) - 1
        let yearPillar = ganzhiForYear(adjustedYear)

        let solarTerms = currentMajorSolarTerm(for: trueSolarDate, timezone: input.timezone)
        let monthBranchIndex = solarTerms.currentJieIndex
        let monthBranch = monthBranchesByJie[monthBranchIndex]
        let monthStem = monthStem(forYearStem: yearPillar.stem, jieIndex: monthBranchIndex)
        let monthPillar = FortunePillar(stem: monthStem, branch: monthBranch)

        let dayPillar = ganzhiForDay(trueSolarDate)
        let hourPillar = ganzhiForHour(dayStem: dayPillar.stem, trueSolarDate: trueSolarDate)

        return FortuneCalendarSnapshot(
            localDate: localDateTime,
            trueSolarDate: trueSolarDate,
            equationOfTimeMinutes: equationOfTime,
            localLongitudeOffsetMinutes: longitudeOffset,
            solarTerm: solarTerms,
            yearPillar: yearPillar,
            monthPillar: monthPillar,
            dayPillar: dayPillar,
            hourPillar: hourPillar
        )
    }

    private static func resolvedSourceDate(for input: FortuneBirthInput) throws -> Date {
        switch input.calendarType {
        case "公历":
            guard let localDate = parseDate(input.birthDate, timezone: input.timezone) else {
                throw FortuneAlgorithmError.invalidInput
            }
            return localDate
        case "农历":
            return try resolveLunarDate(
                input.birthDate,
                isLeapMonth: input.isLeapMonth,
                timezone: input.timezone
            )
        default:
            throw FortuneAlgorithmError.unsupportedCalendar
        }
    }

    private static func resolveLunarDate(_ text: String, isLeapMonth: Bool, timezone: TimeZone) throws -> Date {
        let components = try parseBirthDateComponents(text)
        let chineseCalendar = chineseCalendar(timezone: timezone)
        let cycle = chineseCycleComponents(forGregorianYear: components.year)
        var lunarComponents = DateComponents()
        lunarComponents.calendar = chineseCalendar
        lunarComponents.timeZone = timezone
        lunarComponents.era = cycle.era
        lunarComponents.year = cycle.year
        lunarComponents.month = components.month
        lunarComponents.day = components.day
        lunarComponents.isLeapMonth = isLeapMonth

        guard let resolved = chineseCalendar.date(from: lunarComponents) else {
            throw FortuneAlgorithmError.invalidInput
        }
        return resolved
    }

    private static func parseDate(_ text: String, timezone: TimeZone) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timezone
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter.date(from: text)
    }

    private static func parseBirthDateComponents(_ text: String) throws -> (year: Int, month: Int, day: Int) {
        let values = text.split(separator: "-").compactMap { Int($0) }
        guard values.count == 3 else {
            throw FortuneAlgorithmError.invalidInput
        }
        let year = values[0]
        let month = values[1]
        let day = values[2]
        guard (1900...2100).contains(year), (1...12).contains(month), (1...30).contains(day) else {
            throw FortuneAlgorithmError.invalidInput
        }
        return (year, month, day)
    }

    private static func chineseCycleComponents(forGregorianYear year: Int) -> (era: Int, year: Int) {
        let absoluteChineseYear = year + 2697
        let quotient = absoluteChineseYear / 60
        let remainder = absoluteChineseYear % 60

        if remainder == 0 {
            return (max(1, quotient - 1), 60)
        }

        return (quotient, remainder)
    }

    private static func chineseCalendar(timezone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .chinese)
        calendar.timeZone = timezone
        return calendar
    }

    private static func merge(date: Date, hour: Int, timezone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? date
    }

    private static func calendarYear(for date: Date, timezone: TimeZone) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone
        return calendar.component(.year, from: date)
    }

    private static func nominalHour(for hourLabel: String) -> Int {
        let index = FortuneFieldCatalog.hourOptions.firstIndex(of: hourLabel) ?? 0
        let nominalStarts = [23, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21]
        return nominalStarts[index]
    }

    private static func equationOfTimeMinutes(for date: Date) -> Double {
        let dayOfYear = Double(FortuneLocalHeuristics.dayOfYear(for: date))
        let hour = Double(Calendar(identifier: .gregorian).component(.hour, from: date))
        let gamma = (2.0 * Double.pi / 365.0) * (dayOfYear - 1.0 + (hour - 12.0) / 24.0)
        return 229.18 * (
            0.000075
            + 0.001868 * cos(gamma)
            - 0.032077 * sin(gamma)
            - 0.014615 * cos(2 * gamma)
            - 0.040849 * sin(2 * gamma)
        )
    }

    private static func solarTermMoment(forYearOf date: Date, angle: Double, timezone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone
        let year = calendar.component(.year, from: date)
        return solarTermMoment(forYear: year, angle: angle, timezone: timezone)
    }

    private static func solarTermMoment(forYear year: Int, angle: Double, timezone: TimeZone) -> Date {
        let anchor = majorSolarTermAnchors[angle] ?? (month: 2, day: 4)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone
        var components = DateComponents()
        components.year = year
        components.month = anchor.month
        components.day = anchor.day
        components.hour = 12
        let center = calendar.date(from: components) ?? Date()
        let start = calendar.date(byAdding: .day, value: -20, to: center) ?? center
        let end = calendar.date(byAdding: .day, value: 20, to: center) ?? center
        return searchSolarLongitude(targetAngle: angle, start: start, end: end)
    }

    private static func currentMajorSolarTerm(for date: Date, timezone: TimeZone) -> FortuneSolarTermContext {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone
        let year = calendar.component(.year, from: date)
        var moments: [(index: Int, name: String, date: Date)] = []

        for targetYear in (year - 1)...(year + 1) {
            for (index, item) in majorSolarTerms.enumerated() {
                let moment = solarTermMoment(forYear: targetYear, angle: item.angle, timezone: timezone)
                moments.append((index, item.name, moment))
            }
        }

        let sorted = moments.sorted { $0.date < $1.date }
        let current = sorted.last(where: { $0.date <= date }) ?? sorted[0]
        let next = sorted.first(where: { $0.date > date }) ?? sorted[1]

        return FortuneSolarTermContext(
            currentJieName: current.name,
            currentJieIndex: current.index,
            currentJieDate: current.date,
            nextJieName: next.name,
            nextJieDate: next.date
        )
    }

    private static func searchSolarLongitude(targetAngle: Double, start: Date, end: Date) -> Date {
        var low = start
        var high = end
        let normalizedTarget = normalizedAngle(targetAngle)

        for _ in 0..<40 {
            let interval = high.timeIntervalSince(low)
            let mid = low.addingTimeInterval(interval / 2)
            let midLongitude = normalizedAngle(solarLongitude(for: mid))
            let lowLongitude = normalizedAngle(solarLongitude(for: low))
            let midDistance = normalizedAngle(midLongitude - normalizedTarget)
            let lowDistance = normalizedAngle(lowLongitude - normalizedTarget)

            if signAngle(lowDistance) == signAngle(midDistance) {
                low = mid
            } else {
                high = mid
            }
        }

        return low.addingTimeInterval(high.timeIntervalSince(low) / 2)
    }

    private static func signAngle(_ angle: Double) -> Int {
        let shifted = angle > 180 ? angle - 360 : angle
        return shifted >= 0 ? 1 : -1
    }

    private static func solarLongitude(for date: Date) -> Double {
        let jd = julianDay(for: date)
        let t = (jd - 2451545.0) / 36525.0
        let l0 = normalizedAngle(280.46646 + 36000.76983 * t + 0.0003032 * t * t)
        let m = normalizedAngle(357.52911 + 35999.05029 * t - 0.0001537 * t * t)
        let c =
            (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(deg2rad(m))
            + (0.019993 - 0.000101 * t) * sin(deg2rad(2 * m))
            + 0.000289 * sin(deg2rad(3 * m))
        let theta = l0 + c
        let omega = 125.04 - 1934.136 * t
        return normalizedAngle(theta - 0.00569 - 0.00478 * sin(deg2rad(omega)))
    }

    private static func julianDay(for date: Date) -> Double {
        date.timeIntervalSince1970 / 86400.0 + 2440587.5
    }

    private static func ganzhiForYear(_ year: Int) -> FortunePillar {
        let index = normalizedMod(year - 1984, 60)
        return FortunePillar(
            stem: stems[index % stems.count],
            branch: branches[index % branches.count]
        )
    }

    private static func monthStem(forYearStem yearStem: String, jieIndex: Int) -> String {
        let yearStemIndex = stems.firstIndex(of: yearStem) ?? 0
        let baseIndex: Int
        switch yearStemIndex {
        case 0, 5: baseIndex = 2
        case 1, 6: baseIndex = 4
        case 2, 7: baseIndex = 6
        case 3, 8: baseIndex = 8
        default: baseIndex = 0
        }
        let monthSequenceIndex = jieIndex == 0 ? 11 : jieIndex - 1
        return stems[(baseIndex + monthSequenceIndex) % stems.count]
    }

    private static func ganzhiForDay(_ date: Date) -> FortunePillar {
        let dayNumber = Int(floor(julianDay(for: date) + 0.5))
        let index = normalizedMod(dayNumber + 49, 60)
        return FortunePillar(
            stem: stems[index % stems.count],
            branch: branches[index % branches.count]
        )
    }

    private static func ganzhiForHour(dayStem: String, trueSolarDate: Date) -> FortunePillar {
        let hour = Calendar(identifier: .gregorian).component(.hour, from: trueSolarDate)
        let branchIndex: Int
        switch hour {
        case 23, 0: branchIndex = 0
        case 1, 2: branchIndex = 1
        case 3, 4: branchIndex = 2
        case 5, 6: branchIndex = 3
        case 7, 8: branchIndex = 4
        case 9, 10: branchIndex = 5
        case 11, 12: branchIndex = 6
        case 13, 14: branchIndex = 7
        case 15, 16: branchIndex = 8
        case 17, 18: branchIndex = 9
        case 19, 20: branchIndex = 10
        default: branchIndex = 11
        }
        let startIndex = dayStemHourStemStart[dayStem] ?? 0
        return FortunePillar(
            stem: stems[(startIndex + branchIndex) % stems.count],
            branch: branches[branchIndex]
        )
    }

    private static func hiddenStems(for calendar: FortuneCalendarSnapshot) -> [String: [String]] {
        [
            "年柱": hiddenStemMap[calendar.yearPillar.branch] ?? [],
            "月柱": hiddenStemMap[calendar.monthPillar.branch] ?? [],
            "日柱": hiddenStemMap[calendar.dayPillar.branch] ?? [],
            "时柱": hiddenStemMap[calendar.hourPillar.branch] ?? []
        ]
    }

    private static func scoreFiveElements(calendar: FortuneCalendarSnapshot) -> [String: Int] {
        var scores = Dictionary(uniqueKeysWithValues: fiveElements.map { ($0, 0) })
        let pillars = [calendar.yearPillar, calendar.monthPillar, calendar.dayPillar, calendar.hourPillar]

        for (index, pillar) in pillars.enumerated() {
            let stemWeight = index == 1 ? 20 : (index == 2 ? 18 : 12)
            let branchWeight = index == 1 ? 28 : (index == 2 ? 16 : 10)
            scores[stemElementMap[pillar.stem] ?? "土", default: 0] += stemWeight
            scores[branchMainElements[pillar.branch] ?? "土", default: 0] += branchWeight

            let hiddenWeights = [8, 4, 2]
            for (hiddenIndex, stem) in (hiddenStemMap[pillar.branch] ?? []).enumerated() {
                let weight = hiddenWeights[min(hiddenIndex, hiddenWeights.count - 1)]
                scores[stemElementMap[stem] ?? "土", default: 0] += weight
            }
        }

        applySeasonBoost(monthBranch: calendar.monthPillar.branch, scores: &scores)
        return scores
    }

    private static func applySeasonBoost(monthBranch: String, scores: inout [String: Int]) {
        switch monthBranch {
        case "寅", "卯", "辰":
            scores["木", default: 0] += 18
            scores["火", default: 0] += 6
        case "巳", "午", "未":
            scores["火", default: 0] += 18
            scores["土", default: 0] += 6
        case "申", "酉", "戌":
            scores["金", default: 0] += 18
            scores["水", default: 0] += 4
        default:
            scores["水", default: 0] += 18
            scores["木", default: 0] += 4
        }
    }

    private static func resolveStrengthContext(
        calendar: FortuneCalendarSnapshot,
        scores: [String: Int],
        dayMasterElement: String
    ) -> StrengthContext {
        let monthBranch = calendar.monthPillar.branch
        let monthElement = branchMainElements[monthBranch] ?? "土"
        let monthSupportScore: Int
        let monthReason: String
        if monthElement == dayMasterElement {
            monthSupportScore = 6
            monthReason = "月令主气与日主同气，底盘承接更直接。"
        } else if generates(monthElement, dayMasterElement) {
            monthSupportScore = 5
            monthReason = "月令主气能生扶日主，整体更容易得到时令承接。"
        } else if controls(monthElement, dayMasterElement) {
            monthSupportScore = -5
            monthReason = "月令主气对日主形成制衡，先天节律更容易感到外部压力。"
        } else if generates(dayMasterElement, monthElement) {
            monthSupportScore = -2
            monthReason = "日主之气更多流向月令主气，做事时容易先消耗自己。"
        } else if controls(dayMasterElement, monthElement) {
            monthSupportScore = -1
            monthReason = "日主需要分出力量去制衡月令主气，承载会略显吃力。"
        } else {
            monthSupportScore = 0
            monthReason = "月令与日主之间没有形成明显的直接扶抑。"
        }

        let branchEvidence = [calendar.yearPillar.branch, monthBranch, calendar.dayPillar.branch, calendar.hourPillar.branch]
        var rootSupportScore = 0
        var sameRootCount = 0
        var sourceRootCount = 0
        var controllingRootCount = 0
        for branch in branchEvidence {
            let branchElement = branchMainElements[branch] ?? "土"
            if branchElement == dayMasterElement {
                rootSupportScore += 3
                sameRootCount += 1
            } else if generates(branchElement, dayMasterElement) {
                rootSupportScore += 2
                sourceRootCount += 1
            } else if controls(branchElement, dayMasterElement) {
                rootSupportScore -= 2
                controllingRootCount += 1
            } else if generates(dayMasterElement, branchElement) {
                rootSupportScore -= 1
            }

            for hiddenStem in hiddenStemMap[branch] ?? [] {
                let hiddenElement = stemElementMap[hiddenStem] ?? "土"
                if hiddenElement == dayMasterElement {
                    rootSupportScore += 1
                    sameRootCount += 1
                } else if generates(hiddenElement, dayMasterElement) {
                    rootSupportScore += 1
                    sourceRootCount += 1
                } else if controls(hiddenElement, dayMasterElement) {
                    rootSupportScore -= 1
                    controllingRootCount += 1
                }
            }
        }
        let rootReason = "四支与藏干里，同气根气\(sameRootCount)处、生扶源头\(sourceRootCount)处、受制点\(controllingRootCount)处。"

        let visibleStems = [calendar.yearPillar.stem, calendar.monthPillar.stem, calendar.hourPillar.stem]
        var stemSupportScore = 0
        var stemSupportCount = 0
        var stemPressureCount = 0
        for stem in visibleStems {
            let element = stemElementMap[stem] ?? "土"
            if element == dayMasterElement {
                stemSupportScore += 2
                stemSupportCount += 1
            } else if generates(element, dayMasterElement) {
                stemSupportScore += 2
                stemSupportCount += 1
            } else if controls(element, dayMasterElement) {
                stemSupportScore -= 2
                stemPressureCount += 1
            } else if generates(dayMasterElement, element) || controls(dayMasterElement, element) {
                stemSupportScore -= 1
            }
        }
        let stemReason = "天干透出的助力\(stemSupportCount)处、牵制\(stemPressureCount)处。"

        let selfScore = scores[dayMasterElement, default: 0]
        let average = max(1, scores.values.reduce(0, +) / max(scores.count, 1))
        let balanceScore = max(-5, min(5, (selfScore - average) / 4))
        let balanceReason = "五行量化后，日主\(dayMasterElement)得分\(selfScore)，相对均值\(average)的偏移折算为\(balanceScore)分。"

        let total = monthSupportScore + rootSupportScore + stemSupportScore + balanceScore
        let label: String
        switch total {
        case 14...:
            label = "强"
        case 6...13:
            label = "偏强"
        case -4...5:
            label = "中和"
        case -12 ... -5:
            label = "偏弱"
        default:
            label = "弱"
        }

        let seasonalAdjustment = seasonalAdjustmentElements(
            monthBranch: monthBranch,
            dayMasterElement: dayMasterElement,
            strengthScore: total
        )
        let seasonalReason = seasonalAdjustment.isEmpty
            ? "当前未额外提出明显调候侧重。"
            : "若从调候看，可参考\(seasonalAdjustment.joined(separator: "、"))来缓和时令偏性。"
        let summary = "月令在\(monthBranch)，主气偏\(monthElement)。\(monthReason) \(rootReason) \(stemReason) \(seasonalReason)"

        return StrengthContext(
            label: label,
            score: total,
            seasonalAdjustmentElements: seasonalAdjustment,
            summary: summary,
            evidence: [
                FortuneScoreComponent(
                    key: "strength-month-command",
                    label: "月令扶抑",
                    score: monthSupportScore,
                    reason: monthReason
                ),
                FortuneScoreComponent(
                    key: "strength-rooting",
                    label: "根气承托",
                    score: rootSupportScore,
                    reason: rootReason
                ),
                FortuneScoreComponent(
                    key: "strength-visible-stems",
                    label: "透干助制",
                    score: stemSupportScore,
                    reason: stemReason
                ),
                FortuneScoreComponent(
                    key: "strength-balance",
                    label: "量化平衡",
                    score: balanceScore,
                    reason: balanceReason
                )
            ]
        )
    }

    private static func favorableElements(
        scores: [String: Int],
        dayMasterElement: String,
        strengthLabel: String,
        monthBranch: String,
        seasonalAdjustmentElements: [String]
    ) -> [String] {
        let generationMap: [String: String] = ["木": "水", "火": "木", "土": "火", "金": "土", "水": "金"]
        let drainMap: [String: String] = ["木": "火", "火": "土", "土": "金", "金": "水", "水": "木"]
        let controlMap: [String: String] = ["木": "金", "火": "水", "土": "木", "金": "火", "水": "土"]
        let monthElement = branchMainElements[monthBranch] ?? "土"

        var base: [String]
        if strengthLabel == "强" || strengthLabel == "偏强" {
            base = [drainMap[dayMasterElement], controlMap[dayMasterElement]].compactMap { $0 }
            if monthElement == dayMasterElement || generates(monthElement, dayMasterElement) {
                base = orderedUnique(base + seasonalAdjustmentElements)
            }
        } else {
            base = [dayMasterElement, generationMap[dayMasterElement]].compactMap { $0 }
            if controls(monthElement, dayMasterElement) || strengthLabel == "弱" {
                base = orderedUnique(base + Array(seasonalAdjustmentElements.prefix(1)))
            }
        }

        if base.count < 2 {
            let backup = scores
                .sorted { lhs, rhs in
                    if lhs.value == rhs.value {
                        return lhs.key < rhs.key
                    }
                    return lhs.value > rhs.value
                }
                .map(\.key)
            base = orderedUnique(base + backup)
        }

        return Array(base.prefix(3))
    }

    private static func resolveTenGods(calendar: FortuneCalendarSnapshot) -> [FortuneTenGodSummary] {
        let dayStem = calendar.dayPillar.stem
        let otherStems = [calendar.yearPillar.stem, calendar.monthPillar.stem, calendar.hourPillar.stem]
        var counts = Dictionary(uniqueKeysWithValues: tenGodLabels.map { ($0, 0) })

        for stem in otherStems {
            let label = tenGodLabel(dayStem: dayStem, otherStem: stem)
            counts[label, default: 0] += 1
        }

        for branch in [calendar.yearPillar.branch, calendar.monthPillar.branch, calendar.dayPillar.branch, calendar.hourPillar.branch] {
            for stem in hiddenStemMap[branch] ?? [] {
                let label = tenGodLabel(dayStem: dayStem, otherStem: stem)
                counts[label, default: 0] += 1
            }
        }

        return tenGodLabels.compactMap { label in
            let count = counts[label, default: 0]
            return count > 0 ? FortuneTenGodSummary(label: label, count: count) : nil
        }
    }

    private static func tenGodLabel(dayStem: String, otherStem: String) -> String {
        let dayElement = stemElementMap[dayStem] ?? "土"
        let otherElement = stemElementMap[otherStem] ?? "土"
        let samePolarity = stemPolarity(dayStem) == stemPolarity(otherStem)

        if dayElement == otherElement {
            return samePolarity ? "比肩" : "劫财"
        }
        if generates(dayElement, otherElement) {
            return samePolarity ? "食神" : "伤官"
        }
        if controls(dayElement, otherElement) {
            return samePolarity ? "偏财" : "正财"
        }
        if controls(otherElement, dayElement) {
            return samePolarity ? "七杀" : "正官"
        }

        return samePolarity ? "偏印" : "正印"
    }

    private static func stemPolarity(_ stem: String) -> Int {
        (stems.firstIndex(of: stem) ?? 0).isMultiple(of: 2) ? 1 : -1
    }

    private static func generates(_ from: String, _ to: String) -> Bool {
        switch (from, to) {
        case ("木", "火"), ("火", "土"), ("土", "金"), ("金", "水"), ("水", "木"):
            return true
        default:
            return false
        }
    }

    private static func controls(_ from: String, _ to: String) -> Bool {
        switch (from, to) {
        case ("木", "土"), ("土", "水"), ("水", "火"), ("火", "金"), ("金", "木"):
            return true
        default:
            return false
        }
    }

    private static func resolvePattern(
        calendar: FortuneCalendarSnapshot,
        tenGods: [FortuneTenGodSummary],
        strengthLabel: String
    ) -> (resolvedPattern: String, candidates: [FortuneScoreComponent]) {
        let summary = Dictionary(uniqueKeysWithValues: tenGods.map { ($0.label, $0.count) })
        let monthStemElement = stemElementMap[calendar.monthPillar.stem] ?? "土"
        let dayMasterElement = stemElementMap[calendar.dayPillar.stem] ?? "土"
        let strengthValue = strengthRank(strengthLabel)
        let candidates = [
            FortuneScoreComponent(
                key: "pattern-shangguan-peiyin",
                label: "伤官配印",
                score: summary["伤官", default: 0] * 6 + summary["正印", default: 0] * 5 + summary["偏印", default: 0] * 2,
                reason: "重点看伤官与印星是否同时成势，用于判断表达力与承接力能否并行。"
            ),
            FortuneScoreComponent(
                key: "pattern-shayin-xiangsheng",
                label: "杀印相生",
                score: summary["七杀", default: 0] * 6 + summary["正印", default: 0] * 4 + summary["偏印", default: 0] * 2,
                reason: "重点看七杀与印星是否互相转化，用于判断压力与承载是否能形成正循环。"
            ),
            FortuneScoreComponent(
                key: "pattern-shishen-shengcai",
                label: "食神生财",
                score: summary["食神", default: 0] * 5 + (summary["正财", default: 0] + summary["偏财", default: 0]) * 4,
                reason: "重点看食神与财星是否接续，用于判断输出能力能否顺利转到现实结果。"
            ),
            FortuneScoreComponent(
                key: "pattern-guanyin-xiangsheng",
                label: "官印相生",
                score: (summary["正官", default: 0] + summary["七杀", default: 0]) * 4 + (summary["正印", default: 0] + summary["偏印", default: 0]) * 4,
                reason: "重点看官杀与印星能否彼此承接，用于判断秩序感与执行链条。"
            ),
            FortuneScoreComponent(
                key: "pattern-shenqiang-quxie",
                label: "身强取泄",
                score: strengthValue >= 3 ? 10 + summary["食神", default: 0] * 2 + summary["伤官", default: 0] * 2 : 0,
                reason: "当日主偏强时，更看输出与泄秀是否足够，用于判断是否应先疏导再推进。"
            ),
            FortuneScoreComponent(
                key: "pattern-yueling-fushen",
                label: "月令扶身",
                score: monthStemElement == dayMasterElement ? 9 + strengthValue : 0,
                reason: "若月令之气直接扶助日主，说明命局底盘更依赖时令与根气支撑。"
            ),
            FortuneScoreComponent(
                key: "pattern-fuyi-pingheng",
                label: "扶抑平衡",
                score: max(4, 8 - abs(strengthValue - 2) * 2),
                reason: "当前未见单一路径压倒性成势时，以扶抑平衡作为保守收束。"
            )
        ]
        let sortedCandidates = candidates.sorted { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.label < rhs.label
            }
            return lhs.score > rhs.score
        }
        let resolvedPattern = sortedCandidates.first?.label ?? "扶抑平衡"
        return (resolvedPattern, sortedCandidates)
    }

    private static func makeInterpretation(
        dayMasterElement: String,
        strengthLabel: String,
        strengthSummary: String,
        favorable: [String],
        seasonalAdjustmentElements: [String],
        pattern: String,
        scoreBreakdown: [FortuneScoreComponent]
    ) -> String {
        let favorableText = favorable.joined(separator: "、")
        let dominantElementLine = scoreBreakdown
            .filter { $0.key.hasPrefix("element-") }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.label < rhs.label
                }
                return lhs.score > rhs.score
            }
            .prefix(2)
            .map(\.label)
            .joined(separator: "、")
        let dominanceText = dominantElementLine.isEmpty ? "" : "当前\(dominantElementLine)相对显势，"
        let seasonalText = seasonalAdjustmentElements.isEmpty
            ? ""
            : " 调候上可参考\(seasonalAdjustmentElements.joined(separator: "、"))之势。"
        return "八字参考：日主属\(dayMasterElement)，当前强弱判断为\(strengthLabel)，命局以\(pattern)为主。\(strengthSummary) \(dominanceText)后续更宜借\(favorableText)之势调和全局。\(seasonalText)"
    }

    private static func seasonalAdjustmentElements(
        monthBranch: String,
        dayMasterElement: String,
        strengthScore: Int
    ) -> [String] {
        let seasonalBase: [String]
        switch monthBranch {
        case "寅", "卯", "辰":
            seasonalBase = ["火", "土"]
        case "巳", "午", "未":
            seasonalBase = ["水", "金"]
        case "申", "酉", "戌":
            seasonalBase = ["水", "火"]
        default:
            seasonalBase = ["火", "土"]
        }

        let generationMap: [String: String] = ["木": "水", "火": "木", "土": "火", "金": "土", "水": "金"]
        let drainMap: [String: String] = ["木": "火", "火": "土", "土": "金", "金": "水", "水": "木"]

        if strengthScore <= -5 {
            return Array(orderedUnique([generationMap[dayMasterElement], dayMasterElement].compactMap { $0 } + seasonalBase).prefix(2))
        }
        if strengthScore >= 6 {
            return Array(orderedUnique([drainMap[dayMasterElement]].compactMap { $0 } + seasonalBase).prefix(2))
        }
        return Array(orderedUnique(seasonalBase).prefix(2))
    }

    private static func makeDailySignalHits(
        dayElement: String,
        dailyBranch: String,
        natalBranches: [String],
        favorable: [String],
        natalDayMasterElement: String,
        natalStrengthLabel: String
    ) -> [FortuneRuleHit] {
        var hits: [FortuneRuleHit] = []
        if favorable.contains(dayElement) {
            hits.append(
                FortuneRuleHit(
                    key: "daily-element-favorable",
                    label: "流日五行贴合",
                    score: 6,
                    reason: "流日天干所对应的\(dayElement)气与命局喜用方向相合"
                )
            )
        } else {
            hits.append(
                FortuneRuleHit(
                    key: "daily-element-offset",
                    label: "流日五行偏移",
                    score: -4,
                    reason: "流日五行并非当前命局喜用重点，宜控制节奏"
                )
            )
        }

        if dayElement == natalDayMasterElement {
            hits.append(
                FortuneRuleHit(
                    key: "daily-daymaster-same",
                    label: "流日与日主同气",
                    score: 3,
                    reason: "流日五行与日主同气，今日更容易把个人节奏稳下来。"
                )
            )
        } else if generates(dayElement, natalDayMasterElement) {
            hits.append(
                FortuneRuleHit(
                    key: "daily-daymaster-support",
                    label: "流日生扶日主",
                    score: 4,
                    reason: "流日五行对日主形成生扶，做事时更容易得到顺手的承接力。"
                )
            )
        } else if controls(dayElement, natalDayMasterElement) {
            hits.append(
                FortuneRuleHit(
                    key: "daily-daymaster-pressure",
                    label: "流日克制日主",
                    score: -4,
                    reason: "流日五行对日主形成克制，今日更要避免硬顶节奏和情绪。"
                )
            )
        } else if generates(natalDayMasterElement, dayElement) {
            hits.append(
                FortuneRuleHit(
                    key: "daily-daymaster-drain",
                    label: "流日泄耗日主",
                    score: -2,
                    reason: "流日会带走一部分日主气力，今日更适合先稳住体力与注意力。"
                )
            )
        }

        if natalStrengthLabel == "偏弱" || natalStrengthLabel == "弱" {
            if favorable.contains(dayElement) || generates(dayElement, natalDayMasterElement) {
                hits.append(
                    FortuneRuleHit(
                        key: "daily-weak-master-support",
                        label: "弱局得扶",
                        score: 3,
                        reason: "命局偏弱时遇到当日扶助，宜先把关键小事落地，会更有把握。"
                    )
                )
            }
        } else if natalStrengthLabel == "偏强" || natalStrengthLabel == "强" {
            if dayElement == natalDayMasterElement {
                hits.append(
                    FortuneRuleHit(
                        key: "daily-strong-master-stack",
                        label: "强局再叠",
                        score: -2,
                        reason: "命局已偏强，今日再遇同气时更要防止过满与急推。"
                    )
                )
            }
        }

        let harmonyMatches = natalBranches.filter { sixHarmonyPairs.contains($0 + dailyBranch) }
        for branch in harmonyMatches {
            hits.append(
                FortuneRuleHit(
                    key: "daily-branch-harmony-\(branch)-\(dailyBranch)",
                    label: "流日地支六合",
                    score: 4,
                    reason: "流日地支与原局\(branch)位形成六合，有助于关系与协作"
                )
            )
        }
        if natalBranches.contains(dailyBranch) {
            hits.append(
                FortuneRuleHit(
                    key: "daily-branch-same-\(dailyBranch)",
                    label: "流日地支同气",
                    score: 3,
                    reason: "流日地支与原局同气，做事节奏更容易稳定"
                )
            )
        }

        let clashMatches = natalBranches.filter { clashPairs.contains($0 + dailyBranch) }
        for branch in clashMatches {
            hits.append(
                FortuneRuleHit(
                    key: "daily-branch-clash-\(branch)-\(dailyBranch)",
                    label: "流日地支相冲",
                    score: -5,
                    reason: "流日地支与原局\(branch)位存在冲动关系，重要决定宜放缓"
                )
            )
        }
        let harmMatches = natalBranches.filter { harmPairs.contains($0 + dailyBranch) }
        for branch in harmMatches {
            hits.append(
                FortuneRuleHit(
                    key: "daily-branch-harm-\(branch)-\(dailyBranch)",
                    label: "流日地支相害",
                    score: -3,
                    reason: "流日地支与原局\(branch)位带出相害信号，细碎误读与暗耗更容易累积。"
                )
            )
        }
        let punishmentMatches = natalBranches.filter { punishmentPairs.contains($0 + dailyBranch) }
        for branch in punishmentMatches {
            hits.append(
                FortuneRuleHit(
                    key: "daily-branch-punish-\(branch)-\(dailyBranch)",
                    label: "流日地支相刑",
                    score: -4,
                    reason: "流日地支与原局\(branch)位形成相刑，今天更容易在立场、边界或分寸上起拉扯。"
                )
            )
        }
        return hits
    }

    private static func resolveDailyLevel(totalScore: Int) -> String {
        switch totalScore {
        case 7...:
            return "高"
        case 2...6:
            return "中上"
        case -2...1:
            return "平"
        default:
            return "低"
        }
    }

    private static func makeBaziScoreBreakdown(
        calendar: FortuneCalendarSnapshot,
        scores: [String: Int],
        dayMasterElement: String,
        strengthContext: StrengthContext
    ) -> [FortuneScoreComponent] {
        let average = max(1, scores.values.reduce(0, +) / max(scores.count, 1))
        let selfScore = scores[dayMasterElement, default: 0]
        let elementComponents = fiveElements.map { element in
            let score = scores[element, default: 0]
            let relationText: String
            if element == dayMasterElement {
                relationText = "与日主同气，是判断强弱的核心底盘之一"
            } else {
                switch elementRelationship(from: element, to: dayMasterElement) {
                case "相生":
                    relationText = "与日主之间存在生扶关系，可作为助力来源"
                case "相克":
                    relationText = "与日主之间存在制衡关系，更多承担约束与调节作用"
                default:
                    relationText = "与日主关系相对平衡，用于补足整体层次"
                }
            }
            return FortuneScoreComponent(
                key: "element-\(element)",
                label: "\(element)势",
                score: score,
                reason: "命局中\(element)势累计\(score)分，\(relationText)。"
            )
        }.sorted { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.label < rhs.label
            }
            return lhs.score > rhs.score
        }
        let monthAdjustment = FortuneScoreComponent(
            key: "seasonal-adjustment",
            label: "调候取向",
            score: strengthContext.seasonalAdjustmentElements.isEmpty ? 0 : 1,
            reason: strengthContext.seasonalAdjustmentElements.isEmpty
                ? "当前未额外提出明显调候重点。"
                : "结合\(calendar.monthPillar.branch)月时令，后续可参考\(strengthContext.seasonalAdjustmentElements.joined(separator: "、"))来调和气候偏性。"
        )

        return elementComponents + strengthContext.evidence + [
            FortuneScoreComponent(
                key: "day-master-balance",
                label: "日主平衡",
                score: selfScore - average,
                reason: "日主\(dayMasterElement)得分为\(selfScore)，相对五行均值\(average)的差值为\(selfScore - average)。"
            ),
            monthAdjustment
        ]
    }

    private static func makeDailyYiTags(
        signalHits: [FortuneRuleHit],
        favorable: [String],
        dayElement: String,
        dailyBranch: String,
        natalDayMasterElement: String,
        natalPattern: String,
        natalStrengthLabel: String,
        seed: String
    ) -> [String] {
        var pool: [String] = []

        if favorable.contains(dayElement) {
            pool += ["推进旧案", "会见助力", "确认轻约", "整理方案"]
        } else {
            pool += ["整顿计划", "复盘安排", "守住边界", "留白观察"]
        }

        if signalHits.contains(where: { $0.key.hasPrefix("daily-branch-harmony") }) {
            pool += ["会友", "协商合作", "修复关系", "拜访前辈"]
        }
        if signalHits.contains(where: { $0.key.hasPrefix("daily-branch-same") }) {
            pool += ["整理档案", "规律作息", "确认细节", "清点事项"]
        }
        if signalHits.contains(where: { $0.key.hasPrefix("daily-branch-harm") }) {
            pool += ["先讲清误会点", "把话说完整", "减小默认期待"]
        }
        if signalHits.contains(where: { $0.key.hasPrefix("daily-branch-punish") }) {
            pool += ["先统一尺度", "先定边界再推进", "把规则说在前面"]
        }
        if signalHits.contains(where: { $0.key == "daily-daymaster-support" || $0.key == "daily-weak-master-support" }) {
            pool += ["推进关键节点", "完成积压事项", "先做最重要的一件事"]
        }
        if signalHits.contains(where: { $0.key == "daily-daymaster-same" }) {
            pool += ["稳步推进", "沉下心复盘", "收束旧线"]
        }

        switch dayElement {
        case "木":
            pool += ["学习新知", "拜访助力", "完善计划"]
        case "火":
            pool += ["公开表达", "推进沟通", "确认节奏"]
        case "土":
            pool += ["稳住日常", "落实承诺", "处理家务与现实事务"]
        case "金":
            pool += ["整理规则", "划清边界", "核对重点文件"]
        case "水":
            pool += ["记录灵感", "收拢信息", "静心观察"]
        default:
            break
        }

        switch dailyBranch {
        case "子", "亥":
            pool += ["归拢想法", "调整节律"]
        case "寅", "卯":
            pool += ["启动轻量新计划", "接触新的人和事"]
        case "巳", "午":
            pool += ["明确主次", "推进沟通与表达"]
        case "申", "酉":
            pool += ["整理账目", "核对边界和责任"]
        default:
            pool += ["稳住现实安排", "先收后放"]
        }

        if natalPattern.contains("食神") {
            pool += ["输出成果", "分享想法", "把零散内容整理成稿"]
        } else if natalPattern.contains("伤官") {
            pool += ["打磨方案", "表达观点", "修正细节"]
        } else if natalPattern.contains("杀印") || natalPattern.contains("官印") {
            pool += ["明确责任", "先难后易", "推进正式事项"]
        }

        if natalStrengthLabel == "偏弱" || natalStrengthLabel == "弱" {
            pool += ["先补状态", "聚焦一事", "先稳住体力与专注"]
        } else if natalStrengthLabel == "偏强" || natalStrengthLabel == "强" {
            pool += ["释放积压", "适度分工", "先做收束再扩张"]
        }

        if dayElement == natalDayMasterElement {
            pool += ["顺着自身节律推进", "优先处理最熟悉的事务"]
        }

        return deterministicTagSelection(
            pool,
            count: 3,
            seed: seed,
            fallback: ["复盘安排", "稳步推进", "会见助力"]
        )
    }

    private static func makeDailyJiTags(
        signalHits: [FortuneRuleHit],
        favorable: [String],
        dayElement: String,
        dailyBranch: String,
        natalDayMasterElement: String,
        natalPattern: String,
        natalStrengthLabel: String,
        seed: String
    ) -> [String] {
        var pool: [String] = []

        if signalHits.contains(where: { $0.key.hasPrefix("daily-branch-clash") }) {
            pool += ["仓促决策", "临时变更安排", "硬碰硬沟通", "带情绪拍板"]
        }
        if signalHits.contains(where: { $0.key == "daily-daymaster-pressure" }) {
            pool += ["逞强推进", "替别人扛太多", "在压力下直接下结论"]
        }
        if signalHits.contains(where: { $0.key == "daily-daymaster-drain" }) {
            pool += ["情绪透支", "同时开太多线", "拖到太晚才处理重要事"]
        }
        if signalHits.contains(where: { $0.key.hasPrefix("daily-branch-harm") }) {
            pool += ["把误会拖着不说", "默认对方会懂", "反复消耗耐心"]
        }
        if signalHits.contains(where: { $0.key.hasPrefix("daily-branch-punish") }) {
            pool += ["僵在立场里", "急着分对错", "用情绪顶住规则"]
        }
        if !favorable.contains(dayElement) {
            pool += ["额外承诺", "超额消费", "为了赶进度打乱原计划"]
        }

        switch dayElement {
        case "木":
            pool += ["计划摊得过大", "同时启动太多新方向"]
        case "火":
            pool += ["情绪上头", "把话说满", "急着求结果"]
        case "土":
            pool += ["固执不动", "把小问题拖成大包袱"]
        case "金":
            pool += ["过度挑剔", "把关系谈成对错"]
        case "水":
            pool += ["想太多不落地", "反复犹豫不决"]
        default:
            break
        }

        switch dailyBranch {
        case "子", "亥":
            pool += ["夜间思虑过多", "节律被打乱"]
        case "寅", "卯":
            pool += ["冲动接新任务", "轻忽执行成本"]
        case "巳", "午":
            pool += ["临场起意改方向", "争强好胜"]
        case "申", "酉":
            pool += ["说话太硬", "边界拉得过死"]
        default:
            pool += ["重复承诺", "忽略现实节奏"]
        }

        if natalPattern.contains("伤官") {
            pool += ["口快争胜", "为了表达痛快忽略后续收束"]
        } else if natalPattern.contains("食神") {
            pool += ["沉浸舒适区", "只顾顺手而忽略时效"]
        } else if natalPattern.contains("杀印") || natalPattern.contains("官印") {
            pool += ["把标准提太急", "责任压得过满"]
        }

        if natalStrengthLabel == "偏弱" || natalStrengthLabel == "弱" {
            pool += ["体力透支", "硬顶压力", "在疲惫时继续加码"]
        } else if natalStrengthLabel == "偏强" || natalStrengthLabel == "强" {
            pool += ["过度主导", "替别人做决定", "不留回旋余地"]
        }

        if dayElement == natalDayMasterElement {
            pool += ["顺手就把事情做满", "把熟悉感当成万无一失"]
        }

        return deterministicTagSelection(
            pool,
            count: 3,
            seed: seed,
            fallback: ["仓促决策", "重复承诺", "情绪消费"]
        )
    }

    private static func deterministicTagSelection(
        _ items: [String],
        count: Int,
        seed: String,
        fallback: [String]
    ) -> [String] {
        let merged = orderedUnique(items + fallback)
        let ranked = merged.sorted { lhs, rhs in
            let lhsHash = stableHash(seed + "|" + lhs)
            let rhsHash = stableHash(seed + "|" + rhs)
            if lhsHash == rhsHash {
                return lhs < rhs
            }
            return lhsHash < rhsHash
        }
        return Array(ranked.prefix(count))
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

    private static func normalizedAngle(_ angle: Double) -> Double {
        var value = angle.truncatingRemainder(dividingBy: 360)
        if value < 0 {
            value += 360
        }
        return value
    }

    private static func normalizedMod(_ value: Int, _ mod: Int) -> Int {
        let result = value % mod
        return result >= 0 ? result : result + mod
    }

    private static func deg2rad(_ value: Double) -> Double {
        value * Double.pi / 180
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func relationshipLabel(lhs: String, rhs: String) -> String {
        let pair = lhs + rhs
        if sixHarmonyPairs.contains(pair) {
            return "六合"
        }
        if clashPairs.contains(pair) {
            return "相冲"
        }
        if punishmentPairs.contains(pair) {
            return "相刑"
        }
        if harmPairs.contains(pair) {
            return "相害"
        }
        return "平衡"
    }

    private static func elementRelationship(from: String, to: String) -> String {
        if generates(from, to) || generates(to, from) {
            return "相生"
        }
        if controls(from, to) || controls(to, from) {
            return "相克"
        }
        return "同气"
    }

    private static func strengthRank(_ label: String) -> Int {
        switch label {
        case "强": return 4
        case "偏强": return 3
        case "中和": return 2
        case "偏弱": return 1
        default: return 0
        }
    }

    private static func dominantTenGodLabel(from tenGods: [FortuneTenGodSummary]) -> String {
        tenGods.max { lhs, rhs in
            if lhs.count == rhs.count {
                return lhs.label > rhs.label
            }
            return lhs.count < rhs.count
        }?.label ?? "平衡"
    }

    private static func branchInteractionSummary(
        lhs: FortuneCalendarSnapshot,
        rhs: FortuneCalendarSnapshot
    ) -> (supportDetails: [String], conflictDetails: [String], scoreAdjustment: Int) {
        let positions = [
            ("年柱", lhs.yearPillar.branch, rhs.yearPillar.branch),
            ("月柱", lhs.monthPillar.branch, rhs.monthPillar.branch),
            ("日柱", lhs.dayPillar.branch, rhs.dayPillar.branch),
            ("时柱", lhs.hourPillar.branch, rhs.hourPillar.branch)
        ]

        var supportDetails: [String] = []
        var conflictDetails: [String] = []
        var scoreAdjustment = 0

        for (position, leftBranch, rightBranch) in positions {
            let relation = relationshipLabel(lhs: leftBranch, rhs: rightBranch)
            switch relation {
            case "六合":
                supportDetails.append("\(position)地支\(leftBranch)与\(rightBranch)成六合，相关生活层面更容易达成默契")
                scoreAdjustment += 4
            case "相冲":
                conflictDetails.append("\(position)地支\(leftBranch)与\(rightBranch)相冲，该层面的节奏更需要协商")
                scoreAdjustment -= 5
            case "相刑":
                conflictDetails.append("\(position)地支\(leftBranch)与\(rightBranch)相刑，该层面的立场与分寸更需要反复磨合")
                scoreAdjustment -= 4
            case "相害":
                conflictDetails.append("\(position)地支\(leftBranch)与\(rightBranch)相害，该层面的默契更容易被细碎摩擦消耗")
                scoreAdjustment -= 3
            default:
                if leftBranch == rightBranch {
                    supportDetails.append("\(position)地支同为\(leftBranch)，该层面的节律更易同频")
                    scoreAdjustment += 2
                }
            }
        }

        let lhsBranches = [lhs.yearPillar.branch, lhs.monthPillar.branch, lhs.dayPillar.branch, lhs.hourPillar.branch]
        let rhsBranches = [rhs.yearPillar.branch, rhs.monthPillar.branch, rhs.dayPillar.branch, rhs.hourPillar.branch]
        let punishmentCluster = punishmentClusterSummary(lhsBranches: lhsBranches, rhsBranches: rhsBranches)
        if let conflictLine = punishmentCluster.conflictLine {
            conflictDetails.insert(conflictLine, at: 0)
        }
        scoreAdjustment += punishmentCluster.scoreAdjustment

        return (supportDetails, conflictDetails, scoreAdjustment)
    }

    private static func punishmentClusterSummary(
        lhsBranches: [String],
        rhsBranches: [String]
    ) -> (conflictLine: String?, scoreAdjustment: Int) {
        let combinedBranches = Set(lhsBranches + rhsBranches)

        for triple in punishmentTriples {
            let tripleSet = Set(triple)
            if tripleSet.isSubset(of: combinedBranches) {
                let label = triple.joined(separator: "")
                switch label {
                case "寅巳申":
                    return (
                        "双方命局合看已成\(label)三刑，关系里更容易在节奏推进与主导权上反复拉扯",
                        -6
                    )
                case "丑未戌":
                    return (
                        "双方命局合看已成\(label)三刑，现实责任、分工与边界更容易出现反复牵扯",
                        -6
                    )
                default:
                    return (
                        "双方命局合看已形成\(label)三刑，关系里更容易累积结构性压力",
                        -6
                    )
                }
            }
        }

        return (nil, 0)
    }

    private static func patternInteractionSummary(
        maleAnalysis: FortuneBaziAnalysis,
        femaleAnalysis: FortuneBaziAnalysis
    ) -> (supportLine: String?, conflictLine: String?, scoreAdjustment: Int) {
        let maleDominant = dominantTenGodLabel(from: maleAnalysis.tenGods)
        let femaleDominant = dominantTenGodLabel(from: femaleAnalysis.tenGods)

        if maleAnalysis.resolvedPattern == femaleAnalysis.resolvedPattern {
            return (
                "双方格局同落在\(maleAnalysis.resolvedPattern)，理解方式更容易互相靠近",
                nil,
                4
            )
        }

        if maleDominant == femaleDominant {
            return (
                "双方十神重心同偏\(maleDominant)，做事风格有相近的一面",
                nil,
                2
            )
        }

        if maleDominant == "伤官", femaleDominant == "正官" || maleDominant == "正官", femaleDominant == "伤官" {
            return (
                nil,
                "一方更重表达与突破，另一方更重秩序与规则，遇事更要先统一标准",
                -3
            )
        }

        return (
            "男方格局偏\(maleAnalysis.resolvedPattern)，女方格局偏\(femaleAnalysis.resolvedPattern)，更适合在分工中寻找互补",
            nil,
            1
        )
    }

    private static func normalizedSurname(_ surname: String?) -> String? {
        guard let surname else { return nil }
        let trimmed = surname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let scalars = trimmed.unicodeScalars.filter { (0x4E00...0x9FFF).contains(Int($0.value)) }
        let normalized = String(String.UnicodeScalarView(scalars).prefix(2))
        return normalized.isEmpty ? nil : normalized
    }

    private static func genderAlignment(
        for givenName: NamingGivenNameKnowledge,
        targetGender: String
    ) -> (tier: Int, scoreAdjustment: Int, reason: String) {
        let signature = nameGenderSignature(for: givenName)

        switch (targetGender, signature) {
        case ("男", .masculine):
            return (2, 8, "整体风格更偏沉稳俊朗，与男名取向更贴近")
        case ("男", .neutral):
            return (1, 3, "整体风格偏中性稳健，可作为男名参考")
        case ("男", .feminine):
            return (0, -8, "整体风格偏柔婉，会下调在男名中的排序")
        case ("女", .feminine):
            return (2, 8, "整体风格更偏柔雅清丽，与女名取向更贴近")
        case ("女", .neutral):
            return (1, 3, "整体风格偏中性雅正，可作为女名参考")
        case ("女", .masculine):
            return (0, -8, "整体风格偏峻朗，会下调在女名中的排序")
        default:
            return (1, 0, "整体风格保持中性处理")
        }
    }

    private static func nameGenderSignature(for givenName: NamingGivenNameKnowledge) -> NameGenderSignature {
        switch givenName.genderAffinity {
        case "female":
            return .feminine
        case "male":
            return .masculine
        case "neutral":
            return .neutral
        default:
            break
        }

        let fullText = givenName.leading + givenName.trailing
        let feminineHints = ["妍", "夏", "澜"]
        let masculineHints = ["衡", "礼", "砚", "川"]

        if feminineHints.contains(where: fullText.contains) {
            return .feminine
        }
        if masculineHints.contains(where: fullText.contains) {
            return .masculine
        }

        switch givenName.mood {
        case "温润":
            return .feminine
        case "沉静":
            return .masculine
        default:
            return .neutral
        }
    }

    private enum NameGenderSignature {
        case feminine
        case masculine
        case neutral
    }

    private static func rhythmScore(for fullName: String) -> Int {
        let count = fullName.count
        let scalarBalance = fullName.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 7
        return max(3, 8 - abs(3 - count) + scalarBalance / 2)
    }

    private static func semanticScore(for givenName: NamingGivenNameKnowledge) -> Int {
        var score: Int
        switch givenName.mood {
        case "清朗", "温润":
            score = 8
        case "明曜", "舒展":
            score = 6
        default:
            score = 5
        }

        if givenName.semanticTags.contains(where: { ["安宁", "平衡", "持正", "守礼", "清雅"].contains($0) }) {
            score += 2
        }

        return score
    }

    private static func styleCompatibilityScore(
        surnameTags: Set<String>,
        semanticTags: Set<String>,
        styleLabel: String
    ) -> Int {
        guard !surnameTags.isEmpty else { return styleLabel.contains("雅") ? 2 : 1 }

        let sharedCount = surnameTags.intersection(semanticTags).count
        if sharedCount > 0 {
            return 4 + sharedCount
        }

        if surnameTags.contains("书卷"), styleLabel.contains("雅") {
            return 4
        }
        if surnameTags.contains("常用"), styleLabel.contains("经典") || styleLabel.contains("端") {
            return 3
        }
        return 1
    }

    private static func commonnessScore(for rank: Int) -> Int {
        switch rank {
        case ..<35:
            return 3
        case 35...65:
            return 7
        case 66...80:
            return 5
        default:
            return 4
        }
    }

    private static func writingComplexityPenalty(for complexity: Int) -> Int {
        switch complexity {
        case ..<12:
            return 0
        case 12...20:
            return 1
        case 21...26:
            return 2
        default:
            return 4
        }
    }

    private static func compatibilityRelationTags(
        palaceRelation: String,
        dayMasterRelation: String,
        score: Int,
        complementary: Bool,
        conflicts: [String]
    ) -> [String] {
        var tags: [String] = []
        switch palaceRelation {
        case "六合":
            tags.append("六合")
        case "相冲":
            tags.append("相冲")
        case "相刑":
            tags.append("相刑")
        case "相害":
            tags.append("相害")
        default:
            tags.append("平衡")
        }

        if conflicts.contains(where: { $0.contains("三刑") }) {
            tags.append("三刑")
        }
        tags.append(dayMasterRelation)
        tags.append(complementary ? "互补" : "磨合")
        tags.append(score >= 85 ? "稳定协作" : (score >= 74 ? "稳步磨合" : "谨慎推进"))
        return tags
    }

    private static func compatibilityFocusKeywords(
        support: [String],
        conflicts: [String],
        score: Int
    ) -> [String] {
        var keywords: [String] = []

        if support.contains(where: { $0.contains("节律") || $0.contains("平衡") }) {
            keywords.append("节奏")
        }
        if support.contains(where: { $0.contains("支持") || $0.contains("互补") || $0.contains("默契") }) {
            keywords.append("协作")
        }
        if conflicts.contains(where: { $0.contains("边界") || $0.contains("主导") }) {
            keywords.append("边界")
        }
        if conflicts.contains(where: { $0.contains("分寸") || $0.contains("僵持") }) {
            keywords.append("分寸")
        }
        if conflicts.contains(where: { $0.contains("三刑") || $0.contains("结构性压力") || $0.contains("反复拉扯") }) {
            keywords.append("压力")
        }
        if conflicts.contains(where: { $0.contains("沟通") || $0.contains("让步") || $0.contains("情绪") }) {
            keywords.append("沟通")
        }
        if score < 74 {
            keywords.append("现实安排")
        } else {
            keywords.append("长期计划")
        }

        var deduplicated: [String] = []
        for keyword in keywords where !deduplicated.contains(keyword) {
            deduplicated.append(keyword)
        }
        return deduplicated
    }
}
