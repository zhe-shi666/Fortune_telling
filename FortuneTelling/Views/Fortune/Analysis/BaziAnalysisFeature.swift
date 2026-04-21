import SwiftUI

struct BaziAnalysisPayload: Equatable, Sendable {
    var pillars: [BaziPillarContent]
    var fiveElements: [FiveElementMeterContent]
    var interpretation: String
}

struct BaziInsightRenderContext: Equatable, Sendable {
    var matchedInsight: BaziInsightKnowledge?
    var matchScore: Int
    var matchBreakdown: [FortuneScoreComponent]

    static func resolve(
        analysis: FortuneBaziAnalysis,
        insights: [BaziInsightKnowledge]
    ) -> BaziInsightRenderContext {
        insights.map { insight in
            let breakdown = matchBreakdown(for: insight, analysis: analysis)
            return BaziInsightRenderContext(
                matchedInsight: insight,
                matchScore: breakdown.reduce(0) { $0 + $1.score },
                matchBreakdown: breakdown
            )
        }.max { lhs, rhs in
            if lhs.matchScore == rhs.matchScore {
                return (lhs.matchedInsight?.insightId ?? "") > (rhs.matchedInsight?.insightId ?? "")
            }
            return lhs.matchScore < rhs.matchScore
        } ?? BaziInsightRenderContext(matchedInsight: nil, matchScore: 0, matchBreakdown: [])
    }

    private static func matchBreakdown(
        for insight: BaziInsightKnowledge,
        analysis: FortuneBaziAnalysis
    ) -> [FortuneScoreComponent] {
        let dominantScore = insight.dominantElement == analysis.dayMasterElement ? 8 : -2
        let supportScore = analysis.favorableElements.contains(insight.supportElement) ? 5 : 0
        let strengthScore = insight.strengthLabels.contains(analysis.dayMasterStrengthLabel) ? 7 : -4
        let focusCorpus = (
            [analysis.resolvedPattern, analysis.dayMasterStrengthLabel, analysis.dayMasterElement]
            + analysis.favorableElements
            + analysis.seasonalAdjustmentElements
            + analysis.scoreBreakdown.map(\.label)
            + [analysis.strengthSummary]
        ).joined(separator: " ")
        let focusScore = insight.focusTags.reduce(0) { partialResult, tag in
            partialResult + (focusCorpus.contains(tag) ? 1 : 0)
        }

        return [
            FortuneScoreComponent(
                key: "insight-dominant",
                label: "主五行匹配",
                score: dominantScore,
                reason: dominantScore > 0
                    ? "知识模板主五行为\(insight.dominantElement)，与当前日主一致。"
                    : "知识模板主五行为\(insight.dominantElement)，与当前日主不一致，因此会被下调。"
            ),
            FortuneScoreComponent(
                key: "insight-support",
                label: "喜用匹配",
                score: supportScore,
                reason: supportScore > 0
                    ? "知识模板辅五行\(insight.supportElement)落在当前喜用范围。"
                    : "知识模板辅五行\(insight.supportElement)未命中当前喜用重点。"
            ),
            FortuneScoreComponent(
                key: "insight-strength",
                label: "强弱匹配",
                score: strengthScore,
                reason: strengthScore > 0
                    ? "知识模板支持当前\(analysis.dayMasterStrengthLabel)强弱判断。"
                    : "知识模板不覆盖当前\(analysis.dayMasterStrengthLabel)强弱判断，因此只保留较低优先级。"
            ),
            FortuneScoreComponent(
                key: "insight-focus",
                label: "关注点贴合",
                score: focusScore,
                reason: "知识模板焦点标签与当前解释文本的贴合分为\(focusScore)。"
            )
        ]
    }
}

enum BaziAnalysisServiceError: LocalizedError, Equatable, Sendable {
    case invalidProfile
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidProfile:
            "请补齐出生日期、时辰、性别与历法后再测算。"
        case .serviceUnavailable:
            "当前未能生成八字参考，请稍后再试。"
        }
    }
}

protocol BaziAnalysisServicing: Sendable {
    func analyze(profile: ProfileSnapshot) async throws -> BaziAnalysisPayload
}

struct LocalBaziAnalysisService: BaziAnalysisServicing {
    private let repository: any FortuneLocalRepositorying

    init(repository: any FortuneLocalRepositorying = SwiftDataFortuneRepository.shared) {
        self.repository = repository
    }

    func analyze(profile: ProfileSnapshot) async throws -> BaziAnalysisPayload {
        guard FortuneValidation.isCompleteBirthInput(
            birthDate: profile.birthDate,
            birthHourLabel: profile.birthHourLabel,
            gender: profile.gender,
            calendarType: profile.calendarType
        ) else {
            throw BaziAnalysisServiceError.invalidProfile
        }

        let pillarTitles = ["年柱", "月柱", "日柱", "时柱"]
        let tintMap: [String: UInt32] = [
            "木": 0x7E9E58,
            "火": 0xC97852,
            "土": 0x8A7B57,
            "金": 0xB8A35F,
            "水": 0x6F95B8
        ]
        let analysis = try FortuneAlgorithmEngine.analyzeBazi(
            for: FortuneBirthInput(
                birthDate: profile.birthDate,
                birthHourLabel: profile.birthHourLabel,
                gender: profile.gender,
                calendarType: profile.calendarType,
                isLeapMonth: profile.isLeapMonth
            )
        )
        let insights = try await repository.loadBaziKnowledge()
        let renderContext = BaziInsightRenderContext.resolve(analysis: analysis, insights: insights)
        let pillars = [
            analysis.calendar.yearPillar,
            analysis.calendar.monthPillar,
            analysis.calendar.dayPillar,
            analysis.calendar.hourPillar
        ].enumerated().map { index, pillar in
            BaziPillarContent(
                title: pillarTitles[index],
                heavenlyStem: pillar.label,
                earthlyBranch: elementTone(for: pillar.branch)
            )
        }

        let maxScore = max(analysis.fiveElementScores.values.max() ?? 1, 1)
        let fiveElements = ["木", "火", "土", "金", "水"].map { element in
            let value = analysis.fiveElementScores[element, default: 0]
            return FiveElementMeterContent(
                element: element,
                scoreText: "\(value)%",
                progress: min(Double(value) / Double(maxScore), 1),
                tintHex: tintMap[element] ?? 0x8A7B57
            )
        }

        return BaziAnalysisPayload(
            pillars: pillars,
            fiveElements: fiveElements,
            interpretation: interpretation(for: analysis, renderContext: renderContext)
        )
    }

    private func interpretation(
        for analysis: FortuneBaziAnalysis,
        renderContext: BaziInsightRenderContext
    ) -> String {
        let dominantElements = analysis.scoreBreakdown
            .filter { $0.key.hasPrefix("element-") }
            .prefix(2)
            .map(\.label)
            .joined(separator: "、")
        let weakestElements = analysis.scoreBreakdown
            .filter { $0.key.hasPrefix("element-") }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.label < rhs.label
                }
                return lhs.score < rhs.score
            }
            .prefix(2)
            .map(\.label)
            .joined(separator: "、")
        let patternHint = analysis.patternCandidates.first?.label ?? analysis.resolvedPattern
        let favorableText = analysis.favorableElements.joined(separator: "、")
        let seasonalText = analysis.seasonalAdjustmentElements.isEmpty
            ? ""
            : "调候上可多看\(analysis.seasonalAdjustmentElements.joined(separator: "、"))。"
        let dynamicSummary = "当前格局主看\(patternHint)，日主为\(analysis.dayMasterElement)，强弱落在\(analysis.dayMasterStrengthLabel)。较显的五行在\(dominantElements)，相对偏弱的是\(weakestElements)。后续更宜借\(favorableText)之势调和。"

        guard let matchedInsight = renderContext.matchedInsight else {
            return analysis.interpretation + " " + dynamicSummary
        }

        return matchedInsight.interpretationTemplate
            + " "
            + matchedInsight.advisoryFocus
            + " "
            + analysis.strengthSummary
            + " "
            + dynamicSummary
            + " "
            + seasonalText
    }

    private func elementTone(for branch: String) -> String {
        if branch == "寅" || branch == "卯" {
            return "木势舒展"
        }
        if branch == "巳" || branch == "午" {
            return "火意渐明"
        }
        if branch == "辰" || branch == "戌" || branch == "丑" || branch == "未" {
            return "土气安定"
        }
        if branch == "申" || branch == "酉" {
            return "金风收束"
        }
        return "水势回流"
    }
}

struct MockBaziAnalysisService: BaziAnalysisServicing {
    enum Behavior: Sendable {
        case success
        case failure(BaziAnalysisServiceError)
    }

    var behavior: Behavior = .success

    func analyze(profile: ProfileSnapshot) async throws -> BaziAnalysisPayload {
        switch behavior {
        case .success:
            guard FortuneValidation.isCompleteBirthInput(
                birthDate: profile.birthDate,
                birthHourLabel: profile.birthHourLabel,
                gender: profile.gender,
                calendarType: profile.calendarType
            ) else {
                throw BaziAnalysisServiceError.invalidProfile
            }

            return BaziAnalysisPayload(
                pillars: [
                    BaziPillarContent(title: "年柱", heavenlyStem: "辛亥", earthlyBranch: ""),
                    BaziPillarContent(title: "月柱", heavenlyStem: "戊戌", earthlyBranch: ""),
                    BaziPillarContent(title: "日柱", heavenlyStem: "乙未", earthlyBranch: ""),
                    BaziPillarContent(title: "时柱", heavenlyStem: "戊申", earthlyBranch: "")
                ],
                fiveElements: [
                    FiveElementMeterContent(element: "土", scoreText: "62%", progress: 0.62, tintHex: 0x8A7B57),
                    FiveElementMeterContent(element: "金", scoreText: "95%", progress: 0.95, tintHex: 0x9CB478),
                    FiveElementMeterContent(element: "火", scoreText: "78%", progress: 0.78, tintHex: 0xC58A52),
                    FiveElementMeterContent(element: "木", scoreText: "52%", progress: 0.52, tintHex: 0xB6A16A),
                    FiveElementMeterContent(element: "水", scoreText: "38%", progress: 0.38, tintHex: 0x6F95B8)
                ],
                interpretation: "八字娱乐参考：金水相涵，宜取土金之势以平衡格局。"
            )
        case .failure(let error):
            throw error
        }
    }
}

@MainActor
protocol BaziAnalysisRouting: AnyObject {
    func openTab(_ tab: TodayPrimaryTab)
}

enum BaziAnalysisMockFactory {
    static func empty() -> BaziAnalysisState {
        BaziAnalysisState(
            scenario: .empty,
            activeTab: .analysis,
            title: "命理雅鉴",
            subtitle: "依生辰八字整理五行与格局线索，结果仅作娱乐参考。",
            formTitle: "生辰录入",
            formCaption: "日月、时辰、性别与历法兼备",
            birthDate: "",
            birthHourLabel: FortuneFieldCatalog.hourOptions[8],
            gender: FortuneFieldCatalog.genders[0],
            calendarType: FortuneFieldCatalog.calendars[0],
            isLeapMonth: false,
            calculateButtonTitle: "合取测算",
            resultTitle: "四柱与五行",
            resultCaption: "四柱与五行结果按本地规则整理，仅作娱乐参考",
            pillars: [],
            fiveElements: [],
            interpretation: "",
            inlineMessage: "请先补齐信息，再开始八字娱乐参考测算。",
            emptyContent: BaziEmptyContent(
                title: "缺少命主档案",
                body: "当前没有可复用的命主信息，因此只保留录入表单和保守提示。",
                primaryButtonTitle: "手动录入后测算"
            ),
            errorContent: nil
        )
    }

    static func loading(from base: BaziAnalysisState) -> BaziAnalysisState {
        var next = base
        next.scenario = .loading
        next.inlineMessage = nil
        next.errorContent = nil
        return next
    }

    static func ideal(profile: ProfileSnapshot, payload: BaziAnalysisPayload) -> BaziAnalysisState {
        BaziAnalysisState(
            scenario: .ideal,
            activeTab: .analysis,
            title: "命理雅鉴",
            subtitle: "依生辰八字整理五行与格局线索，结果仅作娱乐参考。",
            formTitle: "生辰录入",
            formCaption: "四柱、时辰、性别与历法兼备",
            birthDate: profile.birthDate,
            birthHourLabel: profile.birthHourLabel,
            gender: profile.gender,
            calendarType: profile.calendarType,
            isLeapMonth: profile.isLeapMonth,
            calculateButtonTitle: "合取测算",
            resultTitle: "四柱与五行",
            resultCaption: "四柱与五行结果按本地规则整理，仅作娱乐参考",
            pillars: payload.pillars,
            fiveElements: payload.fiveElements,
            interpretation: payload.interpretation,
            inlineMessage: nil,
            emptyContent: nil,
            errorContent: nil
        )
    }

    static func error(from base: BaziAnalysisState, message: String) -> BaziAnalysisState {
        var next = base
        next.scenario = .error
        next.inlineMessage = message
        next.errorContent = BaziErrorContent(
            title: "测算暂未成功",
            message: message,
            retryButtonTitle: "重新测算"
        )
        return next
    }
}

@MainActor
final class BaziAnalysisViewModel: ObservableObject {
    @Published var state: BaziAnalysisState
    weak var router: (any BaziAnalysisRouting)?

    private let service: any BaziAnalysisServicing
    private let profileStore: any ProfileStoring
    private let entitlementService: any FortuneEntitlementServicing
    private var hasLoaded = false

    init(
        service: any BaziAnalysisServicing,
        profileStore: any ProfileStoring,
        entitlementService: any FortuneEntitlementServicing = InMemoryFortuneEntitlementService(),
        initialState: BaziAnalysisState = BaziAnalysisMockFactory.empty(),
        router: (any BaziAnalysisRouting)? = nil
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
                var next = BaziAnalysisMockFactory.empty()
                next.birthDate = profile.birthDate
                next.birthHourLabel = profile.birthHourLabel
                next.gender = profile.gender
                next.calendarType = profile.calendarType
                next.isLeapMonth = profile.isLeapMonth
                next.inlineMessage = FortuneProductCopy.usageRule(for: .bazi)
                next.emptyContent = nil
                state = next
            } else {
                state = BaziAnalysisMockFactory.empty()
            }
        } catch {
            state = BaziAnalysisMockFactory.error(from: state, message: error.localizedDescription)
        }
    }

    func send(_ action: BaziAnalysisAction) {
        switch action {
        case .updateBirthDate(let value):
            state.birthDate = value
            clearTransientState()
        case .updateBirthHour(let value):
            state.birthHourLabel = value
            clearTransientState()
        case .updateGender(let value):
            state.gender = value
            clearTransientState()
        case .updateCalendar(let value):
            state.calendarType = value
            if value != "农历" {
                state.isLeapMonth = false
            }
            clearTransientState()
        case .updateLeapMonth(let value):
            state.isLeapMonth = value
            clearTransientState()
        case .calculate:
            Task {
                await consumeAndAnalyze()
            }
        case .retry:
            Task { await refresh() }
        case .openTab(let tab):
            guard tab != .analysis else { return }
            router?.openTab(tab)
        }
    }

    private func analyze(using profile: ProfileSnapshot) async {
        guard FortuneValidation.isCompleteBirthInput(
            birthDate: profile.birthDate,
            birthHourLabel: profile.birthHourLabel,
            gender: profile.gender,
            calendarType: profile.calendarType
        ) else {
            state = BaziAnalysisMockFactory.error(from: state, message: BaziAnalysisServiceError.invalidProfile.localizedDescription)
            return
        }

        let previous = state
        state = BaziAnalysisMockFactory.loading(from: previous)

        do {
            let payload = try await service.analyze(profile: profile)
            state = BaziAnalysisMockFactory.ideal(profile: profile, payload: payload)
        } catch {
            state = BaziAnalysisMockFactory.error(from: previous, message: error.localizedDescription)
        }
    }

    private func consumeAndAnalyze() async {
        let profile = ProfileSnapshot(
            profileId: "bazi-input",
            birthDate: state.birthDate,
            birthHourLabel: state.birthHourLabel,
            gender: state.gender,
            calendarType: state.calendarType,
            isLeapMonth: state.calendarType == "农历" ? state.isLeapMonth : false,
            lastUpdatedAt: ""
        )

        guard FortuneValidation.isCompleteBirthInput(
            birthDate: profile.birthDate,
            birthHourLabel: profile.birthHourLabel,
            gender: profile.gender,
            calendarType: profile.calendarType
        ) else {
            state = BaziAnalysisMockFactory.error(from: state, message: BaziAnalysisServiceError.invalidProfile.localizedDescription)
            return
        }

        do {
            _ = try await entitlementService.consumeIfNeeded(for: .bazi)
            await analyze(using: profile)
        } catch {
            state.inlineMessage = error.localizedDescription
        }
    }

    private func clearTransientState() {
        state.inlineMessage = nil
        state.errorContent = nil
        if state.scenario != .loading {
            state.scenario = .empty
        }
    }
}

struct BaziAnalysisView: View {
    @ObservedObject var viewModel: BaziAnalysisViewModel

    private var canCalculate: Bool {
        FortuneValidation.isCompleteBirthInput(
            birthDate: viewModel.state.birthDate,
            birthHourLabel: viewModel.state.birthHourLabel,
            gender: viewModel.state.gender,
            calendarType: viewModel.state.calendarType
        )
            && viewModel.state.scenario != .loading
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x120F0C), Color(hex: 0x1F1812)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    headerCard
                    formCard

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
                    .opacity(canCalculate ? 1 : 0.45)

                    if let inlineMessage = viewModel.state.inlineMessage {
                        FortuneInlineNotice(
                            message: inlineMessage,
                            tone: viewModel.state.scenario == .error ? .error : .info
                        )
                    }

                    scenarioSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                FortuneMainTabBar(selectedTab: .analysis) { tab in
                    viewModel.send(.openTab(tab))
                }
                .padding(.horizontal, 21)
                .padding(.vertical, 12)
                .background(Color(hex: 0x20170F))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.refreshIfNeeded()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.state.title)
                        .font(FortuneTheme.Typography.sectionTitle)
                        .foregroundStyle(Color(hex: 0xF5ECD8))
                        .minimumScaleFactor(0.88)

                    Text(viewModel.state.subtitle)
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundStyle(Color(hex: 0xD2BF9D))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                FortuneReferenceBadge()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.state.formTitle)
                .font(FortuneTheme.Typography.cardTitle)
                .foregroundStyle(Color(hex: 0xF0DFC2))

            Text(viewModel.state.formCaption)
                .font(FortuneTheme.Typography.small)
                .foregroundStyle(Color(hex: 0x8F7552))
                .fixedSize(horizontal: false, vertical: true)

            FortuneFieldHintText(
                text: "出生日期、出生时辰、生理性别与历法都为必填；普通用户每次测算消耗 1 灵玉，VIP 不消耗。",
                tone: .dark
            )

            darkInputRow(
                title: "出生日期",
                requiredBadge: "必填",
                content: AnyView(
                    FortuneCompactBirthDateField(
                        text: Binding(
                            get: { viewModel.state.birthDate },
                            set: { viewModel.send(.updateBirthDate($0)) }
                        ),
                        tone: .dark,
                        isEnabled: viewModel.state.scenario != .loading
                    )
                )
            )

            darkMenuRow(
                title: "出生时辰",
                value: viewModel.state.birthHourLabel,
                options: FortuneFieldCatalog.hourOptions,
                requiredBadge: "必填"
            ) {
                viewModel.send(.updateBirthHour($0))
            }

            HStack(spacing: 8) {
                darkMenuRow(
                    title: "生理性别",
                    value: viewModel.state.gender,
                    options: FortuneFieldCatalog.genders,
                    requiredBadge: "必填"
                ) {
                    viewModel.send(.updateGender($0))
                }

                darkMenuRow(
                    title: "历法",
                    value: viewModel.state.calendarType,
                    options: FortuneFieldCatalog.calendars,
                    requiredBadge: "必填"
                ) {
                    viewModel.send(.updateCalendar($0))
                }
            }

            if viewModel.state.calendarType == "农历" {
                darkMenuRow(
                    title: "农历月别",
                    value: viewModel.state.isLeapMonth ? "闰月" : "平月",
                    options: ["平月", "闰月"],
                    requiredBadge: "按需"
                ) {
                    viewModel.send(.updateLeapMonth($0 == "闰月"))
                }
            }
        }
        .padding(12)
        .background(Color(hex: 0x18120D))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: 0x5A472F), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var scenarioSection: some View {
        switch viewModel.state.scenario {
        case .ideal:
            resultCard(redacted: false)
        case .loading:
            resultCard(redacted: true)
        case .empty:
            if let content = viewModel.state.emptyContent {
                emptyCard(content)
            }
        case .error:
            if let content = viewModel.state.errorContent {
                errorCard(content)
            }
        }
    }

    private func resultCard(redacted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.state.resultTitle)
                .font(FortuneTheme.Typography.cardTitle)
                .foregroundStyle(Color(hex: 0xF2E2C5))

            Text(viewModel.state.resultCaption)
                .font(FortuneTheme.Typography.small)
                .foregroundStyle(Color(hex: 0x9D845E))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 2), spacing: 0) {
                ForEach(viewModel.state.pillars, id: \.title) { pillar in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pillar.title)
                            .font(FortuneTheme.Typography.small)
                            .foregroundStyle(Color(hex: 0x8F7552))

                        Text(pillar.heavenlyStem)
                            .font(.system(size: 18, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
                    .padding(12)
                    .background(Color(hex: 0x1C150F))
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color(hex: 0x5A472F), lineWidth: 0.5)
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(spacing: 7) {
                ForEach(viewModel.state.fiveElements, id: \.element) { item in
                    HStack(spacing: 8) {
                        Text(item.element)
                            .font(FortuneTheme.Typography.small)
                            .foregroundStyle(Color(hex: 0xE6D0AF))
                            .frame(width: 14, alignment: .leading)

                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(hex: 0x2A2015))
                                Capsule()
                                    .fill(Color(hex: item.tintHex))
                                    .frame(width: max(proxy.size.width * item.progress, 10))
                            }
                        }
                        .frame(height: 6)

                        Text(item.scoreText)
                            .font(FortuneTheme.Typography.small)
                            .foregroundStyle(Color(hex: 0xAF966D))
                            .frame(width: 34, alignment: .trailing)
                    }
                }
            }

            Text(viewModel.state.interpretation)
                .font(FortuneTheme.Typography.small)
                .foregroundStyle(Color(hex: 0xA88957))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color(hex: 0x16110D))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: 0x5A472F), lineWidth: 1)
        )
        .redacted(reason: redacted ? .placeholder : [])
    }

    private func emptyCard(_ content: BaziEmptyContent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(content.title)
                .font(FortuneTheme.Typography.cardTitle)
                .foregroundStyle(Color(hex: 0xF2E2C5))

            Text(content.body)
                .font(FortuneTheme.Typography.body)
                .foregroundStyle(Color(hex: 0xC6B08A))

            Button(content.primaryButtonTitle) {
                viewModel.send(.calculate)
            }
            .buttonStyle(FortuneSecondaryButtonStyle())
        }
        .padding(14)
        .background(Color(hex: 0x16110D))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: 0x5A472F), lineWidth: 1)
        )
    }

    private func errorCard(_ content: BaziErrorContent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(content.title)
                .font(FortuneTheme.Typography.cardTitle)
                .foregroundStyle(Color(hex: 0xF5D7D0))

            Text(content.message)
                .font(FortuneTheme.Typography.body)
                .foregroundStyle(Color(hex: 0xD4B0A7))

            Button(content.retryButtonTitle) {
                viewModel.send(.retry)
            }
            .buttonStyle(FortunePrimaryButtonStyle())
        }
        .padding(14)
        .background(Color(hex: 0x20140F))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: 0x7C4A3E), lineWidth: 1)
        )
    }

    private func darkInputRow(title: String, requiredBadge: String? = nil, content: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            FortuneFieldHeader(title: title, requiredBadge: requiredBadge, tone: .dark)
            content
        }
    }

    private func darkMenuRow(
        title: String,
        value: String,
        options: [String],
        requiredBadge: String? = nil,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            FortuneFieldHeader(title: title, requiredBadge: requiredBadge, tone: .dark)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        onSelect(option)
                    }
                }
            } label: {
                HStack {
                    Text(value)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x8C6D45))
                }
                .fortuneInputChrome(tone: .dark)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }
}
