import SwiftUI

struct CompatibilityReadingPayload: Equatable, Sendable {
    var scoreText: String
    var summaryLines: [String]
}

struct CompatibilityTemplateRenderContext: Equatable, Sendable {
    var matchedTemplate: CompatibilityTemplateKnowledge?
    var matchScore: Int
    var matchBreakdown: [FortuneScoreComponent]
    var tieBreaker: UInt64

    static func resolve(
        analysis: FortuneCompatibilityAnalysis,
        templates: [CompatibilityTemplateKnowledge]
    ) -> CompatibilityTemplateRenderContext {
        let selectionSeed = tieBreakSeed(for: analysis)
        return templates.map { template in
            let breakdown = matchBreakdown(for: template, analysis: analysis)
            return CompatibilityTemplateRenderContext(
                matchedTemplate: template,
                matchScore: breakdown.reduce(0) { $0 + $1.score },
                matchBreakdown: breakdown,
                tieBreaker: stableHash(selectionSeed + "|" + template.templateId)
            )
        }.max { lhs, rhs in
            if lhs.matchScore == rhs.matchScore {
                if lhs.tieBreaker == rhs.tieBreaker {
                    return (lhs.matchedTemplate?.templateId ?? "") > (rhs.matchedTemplate?.templateId ?? "")
                }
                return lhs.tieBreaker > rhs.tieBreaker
            }
            return lhs.matchScore < rhs.matchScore
        } ?? CompatibilityTemplateRenderContext(
            matchedTemplate: nil,
            matchScore: 0,
            matchBreakdown: [],
            tieBreaker: 0
        )
    }

    private static func matchBreakdown(
        for template: CompatibilityTemplateKnowledge,
        analysis: FortuneCompatibilityAnalysis
    ) -> [FortuneScoreComponent] {
        let bandScore = analysis.score >= template.minimumScore && analysis.score <= template.maximumScore ? 8 : 0
        let relationSet = Set(analysis.relationTags)
        let relationScore = template.relationTags.reduce(0) { partialResult, tag in
            partialResult + (relationSet.contains(tag) ? 3 : 0)
        }
        let keywordSet = Set(analysis.focusKeywords)
        let keywordScore = template.focusKeywords.reduce(0) { partialResult, keyword in
            partialResult + (keywordSet.contains(keyword) ? 2 : 0)
        }

        return [
            FortuneScoreComponent(
                key: "template-band",
                label: "分段命中",
                score: bandScore,
                reason: bandScore > 0
                    ? "模板分段 \(template.minimumScore)-\(template.maximumScore) 命中当前契合度。"
                    : "模板分段未直接命中当前契合度。"
            ),
            FortuneScoreComponent(
                key: "template-relations",
                label: "关系标签命中",
                score: relationScore,
                reason: "关系标签命中累计分为\(relationScore)。"
            ),
            FortuneScoreComponent(
                key: "template-focus",
                label: "关注词命中",
                score: keywordScore,
                reason: "关注词命中累计分为\(keywordScore)。"
            )
        ]
    }

    private static func tieBreakSeed(for analysis: FortuneCompatibilityAnalysis) -> String {
        [
            analysis.score.description,
            analysis.overallBand,
            analysis.marriagePalaceRelation,
            analysis.malePattern,
            analysis.femalePattern,
            analysis.dayMasterRelation,
            analysis.relationTags.joined(separator: ","),
            analysis.focusKeywords.joined(separator: ",")
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

enum CompatibilityReadingServiceError: LocalizedError, Equatable, Sendable {
    case missingInput
    case serviceUnavailable
    case unsupportedCalendar

    var errorDescription: String? {
        switch self {
        case .missingInput:
            "请先补齐双方出生日期与时辰，再开始合婚推演。"
        case .serviceUnavailable:
            "当前未能生成合婚参考，请稍后再试。"
        case .unsupportedCalendar:
            "当前仅支持公历与农历信息进行合婚推演。"
        }
    }
}

protocol CompatibilityReadingServicing: Sendable {
    func analyze(male: ProfileSnapshot, female: ProfileSnapshot) async throws -> CompatibilityReadingPayload
}

struct LocalCompatibilityReadingService: CompatibilityReadingServicing {
    private let repository: any FortuneLocalRepositorying

    init(repository: any FortuneLocalRepositorying = SwiftDataFortuneRepository.shared) {
        self.repository = repository
    }

    func analyze(male: ProfileSnapshot, female: ProfileSnapshot) async throws -> CompatibilityReadingPayload {
        guard FortuneValidation.isValidDate(male.birthDate), FortuneValidation.isValidDate(female.birthDate) else {
            throw CompatibilityReadingServiceError.missingInput
        }

        let templates = try await repository.loadCompatibilityKnowledge()
        guard !templates.isEmpty else {
            throw CompatibilityReadingServiceError.serviceUnavailable
        }

        do {
            let analysis = try FortuneAlgorithmEngine.analyzeCompatibility(
                male: birthInput(from: male, fallbackGender: "男"),
                female: birthInput(from: female, fallbackGender: "女")
            )
            let renderContext = CompatibilityTemplateRenderContext.resolve(analysis: analysis, templates: templates)
            let template = renderContext.matchedTemplate
            let seed = compatibilitySeed(male: male, female: female, analysis: analysis)

            return CompatibilityReadingPayload(
                scoreText: "\(analysis.score)%",
                summaryLines: makeSummaryLines(
                    analysis: analysis,
                    template: template,
                    maleHourLabel: male.birthHourLabel,
                    femaleHourLabel: female.birthHourLabel,
                    seed: seed
                )
            )
        } catch let error as FortuneAlgorithmError {
            switch error {
            case .invalidInput:
                throw CompatibilityReadingServiceError.missingInput
            case .unsupportedCalendar:
                throw CompatibilityReadingServiceError.unsupportedCalendar
            }
        } catch {
            throw CompatibilityReadingServiceError.serviceUnavailable
        }
    }

    private func sharedToneLine(score: Int) -> String {
        switch score {
        case 85...:
            return "参考观察：双方已有较强承接基础，更适合把稳定安排做深，而不是停留在感觉层面。"
        case 74...84:
            return "参考观察：彼此有可磨合基础，越能把责任、频率和期待讲清楚，整体越容易稳。"
        default:
            return "参考观察：当前更适合先经营相处方式，把现实安排磨顺，再决定是否放大承诺。"
        }
    }

    private func birthInput(from profile: ProfileSnapshot, fallbackGender: String) -> FortuneBirthInput {
        FortuneBirthInput(
            birthDate: profile.birthDate,
            birthHourLabel: profile.birthHourLabel,
            gender: profile.gender.isEmpty ? fallbackGender : profile.gender,
            calendarType: profile.calendarType.isEmpty ? "公历" : profile.calendarType,
            isLeapMonth: profile.isLeapMonth
        )
    }

    private func bestMatchingTemplate(
        for analysis: FortuneCompatibilityAnalysis,
        templates: [CompatibilityTemplateKnowledge]
    ) -> CompatibilityTemplateKnowledge? {
        CompatibilityTemplateRenderContext.resolve(analysis: analysis, templates: templates).matchedTemplate
    }

    private func templateScore(
        _ template: CompatibilityTemplateKnowledge,
        analysis: FortuneCompatibilityAnalysis
    ) -> Int {
        CompatibilityTemplateRenderContext.resolve(analysis: analysis, templates: [template]).matchScore
    }

    private func makeSummaryLines(
        analysis: FortuneCompatibilityAnalysis,
        template: CompatibilityTemplateKnowledge?,
        maleHourLabel: String,
        femaleHourLabel: String,
        seed: String
    ) -> [String] {
        let focusText = template?.focusKeywords.prefix(2).joined(separator: " / ")
            ?? analysis.focusKeywords.prefix(2).joined(separator: " / ")
        let headline = headlineLine(for: analysis, template: template, seed: seed)
        let elementLine = elementLine(for: analysis, focusText: focusText, template: template, seed: seed)
        let hourDistance = abs(FortuneLocalHeuristics.hourIndex(for: maleHourLabel) - FortuneLocalHeuristics.hourIndex(for: femaleHourLabel))
        let rhythmLine = rhythmLine(
            analysis: analysis,
            hourDistance: hourDistance,
            template: template,
            seed: seed
        )
        let patternLine = patternLine(for: analysis, seed: seed)
        let breakdownLine = scoreBreakdownLine(for: analysis, seed: seed)
        let cautionLine = analysis.conflictMatches.first
            ?? (analysis.score >= 80
                ? (template?.highScoreCaution ?? "参考提醒：遇到分歧时先讲事实，再谈情绪，关系更容易回稳。")
                : (template?.baseCaution ?? "参考提醒：重要决定宜放慢半拍，先把现实安排说清楚，再谈承诺。"))

        return [
            headline,
            elementLine,
            rhythmLine,
            "\(patternLine) \(breakdownLine) \(cautionLine)"
        ]
    }

    private func headlineLine(
        for analysis: FortuneCompatibilityAnalysis,
        template: CompatibilityTemplateKnowledge?,
        seed: String
    ) -> String {
        let bandLabel = template?.bandLabel ?? analysis.overallBand
        let relationLead = marriagePalaceLine(for: analysis.marriagePalaceRelation)
        let extraFocus = rankedSelection(
            [
                analysis.supportMatches.first,
                analysis.conflictMatches.first,
                analysis.branchSupportDetails.first,
                analysis.branchConflictDetails.first
            ].compactMap { $0 },
            seed: seed + "|headline-focus"
        ).first
        let lead = rankedSelection(
            [
                "合婚参考：\(bandLabel)，\(relationLead) 当前命盘契合度为\(analysis.score)%。",
                "合婚参考：目前落在\(bandLabel)，\(relationLead) 本次命盘契合度约为\(analysis.score)%。",
                "合婚参考：两盘当前更接近“\(bandLabel)”区间，\(relationLead) 当前契合度参考为\(analysis.score)%。"
            ],
            seed: seed + "|headline-base"
        ).first ?? "合婚参考：\(bandLabel)。"

        guard let extraFocus else {
            return lead
        }
        return "\(lead) 当前先看：\(extraFocus)。"
    }

    private func elementLine(
        for analysis: FortuneCompatibilityAnalysis,
        focusText: String,
        template: CompatibilityTemplateKnowledge?,
        seed: String
    ) -> String {
        let sharedElements = analysis.sharedFavorableElements.isEmpty
            ? "暂未形成明显共通喜用"
            : "共通喜用在\(analysis.sharedFavorableElements.joined(separator: "、"))"
        let complementText = analysis.isComplementary ? "喜忌配置偏互补" : "喜忌配置存在错位"
        let relationText: String
        switch analysis.dayMasterRelation {
        case "相生":
            relationText = "双方日主呈相生关系，彼此更容易提供支持"
        case "相克":
            relationText = "双方日主存在相克关系，沟通时更要注意节制与让步"
        default:
            relationText = "双方日主同气或相对平衡，推进关系更依赖日常协作"
        }

        let focusSuffix = focusText.isEmpty ? "" : " 当前更适合关注\(focusText)。"
        let supportOrConflict = rankedSelection(
            analysis.supportMatches + analysis.conflictMatches,
            seed: seed + "|element-evidence"
        ).first
        let evidenceSuffix = supportOrConflict.map { " 这组命盘里更明显的一点是：\($0)。" } ?? ""
        let toneSuffix = template.map { " \($0.sharedTone)" } ?? ""
        return "五行协同：\(sharedElements)；男方日主\(analysis.maleDayMasterElement)、女方日主\(analysis.femaleDayMasterElement)，\(relationText)；\(complementText)。\(focusSuffix)\(evidenceSuffix)\(toneSuffix)"
    }

    private func rhythmLine(
        analysis: FortuneCompatibilityAnalysis,
        hourDistance: Int,
        template: CompatibilityTemplateKnowledge?,
        seed: String
    ) -> String {
        let hourText: String
        if hourDistance <= 1 {
            hourText = "双方出生时辰节律接近，生活频率与执行速度更容易对上拍"
        } else if hourDistance <= 4 {
            hourText = "双方出生时辰存在一定节律差，更适合把相处频率和推进顺序说清楚"
        } else {
            hourText = "双方出生时辰跨度较大，长期相处更需要提前约定见面频率、生活节奏与边界"
        }

        let strengthText: String
        if analysis.maleStrengthLabel == analysis.femaleStrengthLabel {
            strengthText = "双方命局强弱同为\(analysis.maleStrengthLabel)，相处时更容易在主导感上保持均衡"
        } else {
            strengthText = "男方命局\(analysis.maleStrengthLabel)、女方命局\(analysis.femaleStrengthLabel)，互动里更要避免一方长期把节奏全握在手里"
        }

        let templateLine = hourDistance <= 2
            ? (template?.nearRhythmLine ?? sharedToneLine(score: analysis.score))
            : (template?.farRhythmLine ?? sharedToneLine(score: analysis.score))
        let dynamicCue = rankedSelection(
            [
                analysis.branchSupportDetails.first,
                analysis.branchConflictDetails.first,
                analysis.supportMatches.dropFirst().first,
                analysis.conflictMatches.dropFirst().first
            ].compactMap { $0 },
            seed: seed + "|rhythm-cue"
        ).first
        let cueSuffix = dynamicCue.map { " 另外，\($0)。" } ?? ""
        return "\(hourText)。\(strengthText)。\(templateLine)\(cueSuffix)"
    }

    private func patternLine(for analysis: FortuneCompatibilityAnalysis, seed: String) -> String {
        let branchSupport = analysis.branchSupportDetails.prefix(1).first
        let branchConflict = analysis.branchConflictDetails.prefix(1).first

        let branchText: String
        if let branchConflict {
            branchText = branchConflict
        } else if let branchSupport {
            branchText = branchSupport
        } else {
            branchText = "四柱支位之间暂未见特别强的同频或冲突信号，关系走势更依赖日常经营"
        }

        let patternText: String
        if analysis.malePattern == analysis.femalePattern {
            patternText = rankedSelection(
                [
                    "双方格局同偏\(analysis.malePattern)，做事驱动力更接近，容易从方法感上互相看懂",
                    "双方格局同偏\(analysis.malePattern)，价值取向更容易靠近，但也可能把同类习惯一起放大",
                    "双方格局同偏\(analysis.malePattern)，彼此对事情轻重的判断更容易接近"
                ],
                seed: seed + "|pattern-same"
            ).first ?? "双方格局同偏\(analysis.malePattern)。"
        } else {
            patternText = rankedSelection(
                [
                    "男方格局偏\(analysis.malePattern)、十神重心在\(analysis.maleDominantTenGod)；女方格局偏\(analysis.femalePattern)、十神重心在\(analysis.femaleDominantTenGod)，彼此更像带着不同驱动力进入关系",
                    "男方偏\(analysis.malePattern)、女方偏\(analysis.femalePattern)，处理事情的出发点并不完全一样，越需要先对齐期待",
                    "男方以\(analysis.maleDominantTenGod)之势更明显、女方以\(analysis.femaleDominantTenGod)之势更明显，互动时容易在优先级上出现不同",
                    "双方分别偏向\(analysis.malePattern)与\(analysis.femalePattern)，更像一方先看推进方式、一方先看承接与边界，所以越要讲清现实分工"
                ],
                seed: seed + "|pattern-diff"
            ).first ?? "双方格局重心不同。"
        }

        return "命盘细节：\(branchText)。\(patternText)。"
    }

    private func scoreBreakdownLine(for analysis: FortuneCompatibilityAnalysis, seed: String) -> String {
        let effectiveItems = analysis.scoreBreakdown.filter {
            $0.key != "base" && $0.key != "score-calibration" && $0.score != 0
        }
        let positiveLabels = effectiveItems
            .filter { $0.score > 0 }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.label < rhs.label
                }
                return lhs.score > rhs.score
            }
            .prefix(2)
            .map(\.label)
        let negativeLabels = effectiveItems
            .filter { $0.score < 0 }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.label < rhs.label
                }
                return lhs.score < rhs.score
            }
            .prefix(2)
            .map(\.label)

        let positiveText = positiveLabels.isEmpty ? "当前未见特别强的结构加分" : "主要加分在\(positiveLabels.joined(separator: "、"))"
        let negativeText = negativeLabels.isEmpty ? "暂未见明显结构性扣分" : "主要留意\(negativeLabels.joined(separator: "、"))"
        let extraExplain = rankedSelection(
            analysis.supportMatches + analysis.conflictMatches,
            seed: seed + "|score-explain"
        ).first
        let explainSuffix = extraExplain.map { " 更落地地看，就是：\($0)。" } ?? ""
        return "本次分值参考里，\(positiveText)；\(negativeText)。\(explainSuffix)"
    }

    private func marriagePalaceLine(for relation: String) -> String {
        switch relation {
        case "六合":
            return "夫妻宫形成六合，彼此更容易先建立默契。"
        case "相冲":
            return "夫妻宫存在相冲，现实节奏与情绪表达更需要经营。"
        case "相刑":
            return "夫妻宫存在相刑，遇事更容易卡在立场和分寸上。"
        case "相害":
            return "夫妻宫存在相害，细碎摩擦更容易慢慢消耗默契。"
        default:
            return "夫妻宫暂无明显强冲，适合先从稳定协作慢慢累积信任。"
        }
    }

    private func compatibilitySeed(
        male: ProfileSnapshot,
        female: ProfileSnapshot,
        analysis: FortuneCompatibilityAnalysis
    ) -> String {
        [
            male.profileId,
            male.birthDate,
            male.birthHourLabel,
            female.profileId,
            female.birthDate,
            female.birthHourLabel,
            analysis.score.description,
            analysis.malePattern,
            analysis.femalePattern,
            analysis.marriagePalaceRelation,
            analysis.dayMasterRelation
        ].joined(separator: "|")
    }

    private func rankedSelection(_ items: [String], seed: String) -> [String] {
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

    private func orderedUnique(_ items: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for item in items where !item.isEmpty {
            if seen.insert(item).inserted {
                result.append(item)
            }
        }
        return result
    }

    private func stableHash(_ value: String) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return hash
    }
}

struct MockCompatibilityReadingService: CompatibilityReadingServicing {
    enum Behavior: Sendable {
        case success
        case failure(CompatibilityReadingServiceError)
    }

    var behavior: Behavior = .success

    func analyze(male: ProfileSnapshot, female: ProfileSnapshot) async throws -> CompatibilityReadingPayload {
        switch behavior {
        case .success:
            guard FortuneValidation.isValidDate(male.birthDate), FortuneValidation.isValidDate(female.birthDate) else {
                throw CompatibilityReadingServiceError.missingInput
            }
            return CompatibilityReadingPayload(
                scoreText: "88%",
                summaryLines: [
                    "合婚参考：彼此处事节奏相近，较容易形成默契。",
                    "参考观察：日常安排更适合先从稳定共识做起，再决定重要承诺。",
                    "参考提醒：遇到分歧时先放慢节奏，守礼让会更稳。"
                ]
            )
        case .failure(let error):
            throw error
        }
    }
}

@MainActor
protocol CompatibilityReadingRouting: AnyObject {
    func openTab(_ tab: TodayPrimaryTab)
}

enum CompatibilityReadingMockFactory {
    static func empty() -> CompatibilityReadingState {
        CompatibilityReadingState(
            scenario: .empty,
            activeTab: .compatibility,
            title: "琴瑟和鸣",
            subtitle: "先录入双方生辰信息，再以古法整理五行与命宫线索，结果仅作娱乐参考。",
            maleBirthDate: "1996-08-14",
            maleBirthHourLabel: FortuneFieldCatalog.hourOptions[9],
            femaleBirthDate: "",
            femaleBirthHourLabel: FortuneFieldCatalog.hourOptions[3],
            calculateButtonTitle: "开始合婚推演",
            resultTitle: "命盘契合度",
            scoreText: "--",
            summaryLines: [],
            inlineMessage: "至少需要双方的出生日期与时辰，普通用户每次推演消耗 1 灵玉，VIP 不消耗。"
        )
    }

    static func loading(from state: CompatibilityReadingState) -> CompatibilityReadingState {
        var next = state
        next.scenario = .loading
        next.inlineMessage = nil
        return next
    }

    static func ideal(
        male: ProfileSnapshot,
        female: ProfileSnapshot,
        payload: CompatibilityReadingPayload
    ) -> CompatibilityReadingState {
        CompatibilityReadingState(
            scenario: .ideal,
            activeTab: .compatibility,
            title: "琴瑟和鸣",
            subtitle: "先录入双方生辰信息，再以古法整理五行与命宫线索，结果仅作娱乐参考。",
            maleBirthDate: male.birthDate,
            maleBirthHourLabel: male.birthHourLabel,
            femaleBirthDate: female.birthDate,
            femaleBirthHourLabel: female.birthHourLabel,
            calculateButtonTitle: "开始合婚推演",
            resultTitle: "命盘契合度",
            scoreText: payload.scoreText,
            summaryLines: payload.summaryLines,
            inlineMessage: nil
        )
    }

    static func error(from state: CompatibilityReadingState, message: String) -> CompatibilityReadingState {
        var next = state
        next.scenario = .error
        next.inlineMessage = message
        next.scoreText = "--"
        next.summaryLines = []
        return next
    }
}

@MainActor
final class CompatibilityReadingViewModel: ObservableObject {
    @Published var state: CompatibilityReadingState
    weak var router: (any CompatibilityReadingRouting)?

    private let service: any CompatibilityReadingServicing
    private let profileStore: any ProfileStoring
    private let entitlementService: any FortuneEntitlementServicing
    private var hasLoaded = false

    init(
        service: any CompatibilityReadingServicing,
        profileStore: any ProfileStoring,
        entitlementService: any FortuneEntitlementServicing = InMemoryFortuneEntitlementService(),
        initialState: CompatibilityReadingState = CompatibilityReadingMockFactory.empty(),
        router: (any CompatibilityReadingRouting)? = nil
    ) {
        self.service = service
        self.profileStore = profileStore
        self.entitlementService = entitlementService
        self.state = initialState
        self.router = router
    }

    func refreshIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await refresh()
    }

    func refresh() async {
        do {
            if let profile = try await profileStore.loadProfile() {
                var next = CompatibilityReadingMockFactory.empty()
                next.femaleBirthDate = profile.birthDate
                next.femaleBirthHourLabel = profile.birthHourLabel
                next.inlineMessage = FortuneProductCopy.usageRule(for: .compatibility)
                state = next
            } else {
                state = CompatibilityReadingMockFactory.empty()
            }
        } catch {
            state = CompatibilityReadingMockFactory.error(from: state, message: error.localizedDescription)
        }
    }

    func send(_ action: CompatibilityReadingAction) {
        switch action {
        case .updateMaleBirthDate(let value):
            state.maleBirthDate = value
            clearTransientState()
        case .updateMaleBirthHour(let value):
            state.maleBirthHourLabel = value
            clearTransientState()
        case .updateFemaleBirthDate(let value):
            state.femaleBirthDate = value
            clearTransientState()
        case .updateFemaleBirthHour(let value):
            state.femaleBirthHourLabel = value
            clearTransientState()
        case .calculate:
            Task {
                await consumeAndCalculate()
            }
        case .openTab(let tab):
            guard tab != .compatibility else { return }
            router?.openTab(tab)
        }
    }

    private func calculate(male: ProfileSnapshot, female: ProfileSnapshot) async {
        guard FortuneValidation.isValidDate(male.birthDate), FortuneValidation.isValidDate(female.birthDate) else {
            state = CompatibilityReadingMockFactory.error(from: state, message: CompatibilityReadingServiceError.missingInput.localizedDescription)
            return
        }

        let previous = state
        state = CompatibilityReadingMockFactory.loading(from: previous)

        do {
            let payload = try await service.analyze(male: male, female: female)
            state = CompatibilityReadingMockFactory.ideal(male: male, female: female, payload: payload)
        } catch {
            state = CompatibilityReadingMockFactory.error(from: previous, message: error.localizedDescription)
        }
    }

    private func consumeAndCalculate() async {
        let male = ProfileSnapshot(
            profileId: "male-manual",
            birthDate: state.maleBirthDate,
            birthHourLabel: state.maleBirthHourLabel,
            gender: "男",
            calendarType: "公历",
            lastUpdatedAt: ""
        )
        let female = ProfileSnapshot(
            profileId: "female-manual",
            birthDate: state.femaleBirthDate,
            birthHourLabel: state.femaleBirthHourLabel,
            gender: "女",
            calendarType: "公历",
            lastUpdatedAt: ""
        )

        guard FortuneValidation.isValidDate(male.birthDate), FortuneValidation.isValidDate(female.birthDate) else {
            state = CompatibilityReadingMockFactory.error(from: state, message: CompatibilityReadingServiceError.missingInput.localizedDescription)
            return
        }

        do {
            _ = try await entitlementService.consumeIfNeeded(for: .compatibility)
            await calculate(male: male, female: female)
        } catch {
            state.inlineMessage = error.localizedDescription
        }
    }

    private func clearTransientState() {
        state.inlineMessage = nil
        state.scoreText = "--"
        state.summaryLines = []
        if state.scenario != .loading {
            state.scenario = .empty
        }
    }
}

struct CompatibilityReadingView: View {
    @ObservedObject var viewModel: CompatibilityReadingViewModel

    private var canCalculate: Bool {
        FortuneValidation.isValidDate(viewModel.state.maleBirthDate)
            && FortuneValidation.isValidDate(viewModel.state.femaleBirthDate)
            && FortuneValidation.isValidBirthHour(viewModel.state.maleBirthHourLabel)
            && FortuneValidation.isValidBirthHour(viewModel.state.femaleBirthHourLabel)
            && viewModel.state.scenario != .loading
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x090704), Color(hex: 0x161008)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    heroCard
                    personCard(
                        title: "男方生辰",
                        helperText: nil,
                        birthDate: Binding(
                            get: { viewModel.state.maleBirthDate },
                            set: { viewModel.send(.updateMaleBirthDate($0)) }
                        ),
                        hourLabel: viewModel.state.maleBirthHourLabel
                    ) {
                        viewModel.send(.updateMaleBirthHour($0))
                    }
                    personCard(
                        title: "女方生辰",
                        helperText: "另一方需填写出生日期与时辰后，才能开始合婚推演。",
                        birthDate: Binding(
                            get: { viewModel.state.femaleBirthDate },
                            set: { viewModel.send(.updateFemaleBirthDate($0)) }
                        ),
                        hourLabel: viewModel.state.femaleBirthHourLabel
                    ) {
                        viewModel.send(.updateFemaleBirthHour($0))
                    }

                    Button {
                        viewModel.send(.calculate)
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.state.scenario == .loading {
                                ProgressView()
                                    .tint(FortuneTheme.Palette.textOnDark)
                            }
                            Text(viewModel.state.calculateButtonTitle)
                        }
                    }
                    .buttonStyle(FortunePrimaryButtonStyle())
                    .disabled(!canCalculate)
                    .opacity(canCalculate ? 1 : 0.5)

                    if let inlineMessage = viewModel.state.inlineMessage {
                        FortuneInlineNotice(
                            message: inlineMessage,
                            tone: viewModel.state.scenario == .error ? .error : .info
                        )
                    }

                    resultCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                FortuneMainTabBar(selectedTab: .compatibility) { tab in
                    viewModel.send(.openTab(tab))
                }
                .padding(.horizontal, 21)
                .padding(.vertical, 12)
                .background(Color(hex: 0x1A140D))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.refreshIfNeeded()
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.state.title)
                        .font(FortuneTheme.Typography.sectionTitle)
                        .foregroundStyle(Color(hex: 0xF5ECD8))
                        .minimumScaleFactor(0.88)

                    Text(viewModel.state.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: 0xCDBE9E))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                FortuneReferenceBadge()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x221A12), Color(hex: 0x3A2B1E)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0x6E5A3B), lineWidth: 1)
        )
    }

    private func personCard(
        title: String,
        helperText: String?,
        birthDate: Binding<String>,
        hourLabel: String,
        onSelectHour: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FortuneFieldHeader(title: title, requiredBadge: "必填", tone: .dark)

            if let helperText {
                FortuneFieldHintText(text: helperText, tone: .dark)
            }

            formRow(birthDate: birthDate, hourLabel: hourLabel, onSelectHour: onSelectHour)
        }
        .padding(12)
        .background(Color(hex: 0x15100B))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: 0x4B3B26), lineWidth: 1)
        )
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(viewModel.state.resultTitle)
                    .font(FortuneTheme.Typography.cardTitle)
                    .foregroundStyle(Color(hex: 0xF4E6CE))

                Spacer()

                Text(viewModel.state.scoreText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: 0xF6D27A))
            }

            ZStack(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(Color(hex: 0x2A2015))

                    Capsule()
                        .fill(Color(hex: 0xCDA861))
                        .frame(width: max(proxy.size.width * progressFraction, 10))
                }
            }
            .frame(height: 8)

            ForEach(viewModel.state.summaryLines, id: \.self) { line in
                Text("• \(line)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0xB8A482))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if viewModel.state.summaryLines.isEmpty {
                FortuneFieldHintText(
                    text: "补齐双方的出生日期与出生时辰后，系统才会生成命盘契合度与推演说明。",
                    tone: .dark
                )
            }
        }
        .padding(14)
        .background(Color(hex: 0x14100A))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: 0x4F3D26), lineWidth: 1)
        )
        .redacted(reason: viewModel.state.scenario == .loading ? .placeholder : [])
    }

    private func formRow(
        birthDate: Binding<String>,
        hourLabel: String,
        onSelectHour: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: 8) {
            FortuneCompactBirthDateField(
                text: birthDate,
                tone: .dark,
                isEnabled: viewModel.state.scenario != .loading
            )

            Menu {
                ForEach(FortuneFieldCatalog.hourOptions, id: \.self) { option in
                    Button(option) {
                        onSelectHour(option)
                    }
                }
            } label: {
                HStack {
                    Text(hourLabel)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: 0x9F7D4D))
                }
                .fortuneInputChrome(tone: .dark)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
    }

    private var progressFraction: CGFloat {
        guard let percent = Double(viewModel.state.scoreText.replacingOccurrences(of: "%", with: "")) else {
            return 0
        }
        return max(0, min(percent / 100, 1))
    }
}
