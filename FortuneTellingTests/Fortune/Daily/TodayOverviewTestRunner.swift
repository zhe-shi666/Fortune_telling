import XCTest
@testable import FortuneTelling

final class TodayOverviewTestRunner: XCTestCase {
    func testDailyServiceUsesLocalKnowledgeAndProfile() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        try await repository.saveProfile(.sample)

        let service = LocalDailyFortuneService(repository: repository)
        let payload = try await service.fetchDailyFortune(for: .sample, on: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(payload.heroTitle, "黄历今朝")
        XCTAssertFalse(payload.heroSubtitle.isEmpty)
        XCTAssertTrue(payload.recommendedLine.hasPrefix("宜："))
        XCTAssertTrue(payload.cautionLine.hasPrefix("忌："))
        XCTAssertTrue(payload.oraclePreview.contains("签曰"))
        XCTAssertTrue(payload.ganzhiValue.contains("·"))
        XCTAssertFalse(payload.oracleDetail.category.isEmpty)
    }

    func testDailyGoldenSampleMatchesStructuredKnowledgeSelection() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        try await repository.saveProfile(.sample)
        let service = LocalDailyFortuneService(repository: repository)
        let payload = try await service.fetchDailyFortune(
            for: .sample,
            on: Date(timeIntervalSince1970: 1_744_992_000)
        )

        XCTAssertTrue(payload.heroSubtitle.contains("结合公历档案与戌时 (19:00-21:00)整理的今日参考"))
        XCTAssertTrue(payload.heroSubtitle.contains("流日戊午与命局木日主相映"))
        XCTAssertTrue(payload.ganzhiValue.hasPrefix("戊午 · "))
        XCTAssertTrue(payload.ganzhiValue.contains(" · 女命 · 戌时"))
        XCTAssertTrue(payload.recommendedLine.hasPrefix("宜："))
        XCTAssertEqual(payload.recommendedLine.components(separatedBy: "、").count, 3)
        XCTAssertTrue(payload.cautionLine.hasPrefix("忌："))
        XCTAssertEqual(payload.cautionLine.components(separatedBy: "、").count, 3)
        XCTAssertTrue(payload.oraclePreview.hasPrefix("签曰："))
        XCTAssertFalse(payload.oraclePreview.replacingOccurrences(of: "签曰：", with: "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertGreaterThan(payload.oraclePreview.count, 12)
        XCTAssertEqual(payload.oracleDetail.title, "今日解签")
        XCTAssertTrue(payload.oracleDetail.category.contains("签 · "))
        XCTAssertFalse(payload.oracleDetail.body.isEmpty)
        XCTAssertFalse(payload.oracleDetail.adviceBody.isEmpty)
        XCTAssertTrue(payload.oracleDetail.triggerHint.contains("同一人每天"))
    }

    func testDailyServiceIsStableForSamePersonOnSameDate() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        try await repository.saveProfile(.sample)
        let service = LocalDailyFortuneService(repository: repository)
        let targetDate = Date(timeIntervalSince1970: 1_744_992_000)

        let first = try await service.fetchDailyFortune(for: .sample, on: targetDate)
        let second = try await service.fetchDailyFortune(for: .sample, on: targetDate)

        XCTAssertEqual(first, second)
    }

    func testDailyServiceChangesForDifferentPeopleOrDifferentDates() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        try await repository.saveProfile(.sample)
        var anotherProfile = ProfileSnapshot.sample
        anotherProfile.profileId = "sample-another"
        anotherProfile.birthDate = "1991-02-14"
        anotherProfile.birthHourLabel = FortuneFieldCatalog.hourOptions[3]
        anotherProfile.gender = "男"
        try await repository.saveProfile(anotherProfile)

        let service = LocalDailyFortuneService(repository: repository)
        let baseDate = Date(timeIntervalSince1970: 1_744_992_000)
        let nextDate = Date(timeIntervalSince1970: 1_745_078_400)

        let basePayload = try await service.fetchDailyFortune(for: .sample, on: baseDate)
        let otherDatePayload = try await service.fetchDailyFortune(for: .sample, on: nextDate)
        let otherProfilePayload = try await service.fetchDailyFortune(for: anotherProfile, on: baseDate)

        XCTAssertNotEqual(basePayload.recommendedLine + basePayload.cautionLine + basePayload.oraclePreview,
                          otherDatePayload.recommendedLine + otherDatePayload.cautionLine + otherDatePayload.oraclePreview)
        XCTAssertNotEqual(basePayload.recommendedLine + basePayload.cautionLine + basePayload.oraclePreview,
                          otherProfilePayload.recommendedLine + otherProfilePayload.cautionLine + otherProfilePayload.oraclePreview)
    }

    func testDailyAlgorithmProducesSignalHitsAndRenderTrace() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let insight = try FortuneAlgorithmEngine.analyzeDaily(
            for: FortuneBirthInput(
                birthDate: ProfileSnapshot.sample.birthDate,
                birthHourLabel: ProfileSnapshot.sample.birthHourLabel,
                gender: ProfileSnapshot.sample.gender,
                calendarType: ProfileSnapshot.sample.calendarType
            ),
            targetDate: Date(timeIntervalSince1970: 1_744_992_000)
        )
        let knowledge = try await repository.loadDailyKnowledge()
        let renderContext = DailyFortuneRenderContext.resolve(insight: insight, knowledge: knowledge)

        XCTAssertFalse(insight.signalHits.isEmpty)
        XCTAssertEqual(insight.scoreBreakdown.count, insight.signalHits.count)
        XCTAssertTrue(insight.scoreBreakdown.contains(where: { $0.score > 0 }))
        XCTAssertTrue(insight.scoreBreakdown.contains(where: { $0.score < 0 }))
        XCTAssertFalse(renderContext.matchBreakdown.isEmpty)
        XCTAssertGreaterThan(renderContext.matchScore, 0)
        XCTAssertTrue(renderContext.matchedRule.ruleId.hasPrefix("daily-"))
        XCTAssertFalse(renderContext.matchedRule.recommendations.isEmpty)
        XCTAssertTrue(renderContext.matchBreakdown.contains(where: { $0.label == "吉凶层级匹配" && $0.score > 0 }))
    }

    @MainActor
    func testTodayOverviewRefreshFallsBackToEmptyWhenProfileMissing() async {
        let viewModel = TodayOverviewViewModel(
            service: MockDailyFortuneService(),
            profileStore: InMemoryProfileStore(profile: nil),
            initialState: TodayOverviewMockFactory.make(.loading)
        )

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state.scenario, .empty)
        XCTAssertNotNil(viewModel.state.profilePrompt)
        XCTAssertNil(viewModel.state.oracleDetail)
    }

    @MainActor
    func testTodayOverviewRefreshFallsBackToEmptyWhenProfileIncomplete() async {
        var brokenProfile = ProfileSnapshot.sample
        brokenProfile.birthHourLabel = ""

        let viewModel = TodayOverviewViewModel(
            service: MockDailyFortuneService(),
            profileStore: InMemoryProfileStore(profile: brokenProfile),
            initialState: TodayOverviewMockFactory.make(.loading)
        )

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state.scenario, .empty)
        XCTAssertEqual(viewModel.state.inlineMessage, "请先补齐出生日期、时辰、性别与历法后，再查看今日参考。")
        XCTAssertNotNil(viewModel.state.profilePrompt)
    }

    @MainActor
    func testTodayOverviewRefreshShowsErrorWhenServiceFails() async {
        let viewModel = TodayOverviewViewModel(
            service: MockDailyFortuneService(behavior: .failure(.serviceUnavailable)),
            profileStore: InMemoryProfileStore(profile: .sample),
            initialState: TodayOverviewMockFactory.make(.loading)
        )

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state.scenario, .error)
        XCTAssertEqual(viewModel.state.errorContent?.message, DailyFortuneServiceError.serviceUnavailable.localizedDescription)
    }

    @MainActor
    func testTodayOverviewPresentOracleConsumesEntitlementAndShowsSheet() async {
        let entitlement = InMemoryFortuneEntitlementService(jadeBalance: 2, isVIPActive: false)
        let viewModel = TodayOverviewViewModel(
            service: MockDailyFortuneService(),
            profileStore: InMemoryProfileStore(profile: .sample),
            entitlementService: entitlement,
            initialState: TodayOverviewMockFactory.makeIdeal(from: .sample(for: .sample, on: Date(timeIntervalSince1970: 0)))
        )

        viewModel.send(.presentOracle(true))
        await waitForAsyncState()

        let snapshot = await entitlement.loadSnapshot()
        XCTAssertTrue(viewModel.state.isOracleSheetPresented)
        XCTAssertNil(viewModel.state.inlineMessage)
        XCTAssertEqual(snapshot.jadeBalance, 1)
    }

    @MainActor
    func testTodayOverviewPresentOracleShowsEntitlementErrorWhenJadeInsufficient() async {
        let entitlement = InMemoryFortuneEntitlementService(jadeBalance: 0, isVIPActive: false)
        let viewModel = TodayOverviewViewModel(
            service: MockDailyFortuneService(),
            profileStore: InMemoryProfileStore(profile: .sample),
            entitlementService: entitlement,
            initialState: TodayOverviewMockFactory.makeIdeal(from: .sample(for: .sample, on: Date(timeIntervalSince1970: 0)))
        )

        viewModel.send(.presentOracle(true))
        await waitForAsyncState()

        XCTAssertFalse(viewModel.state.isOracleSheetPresented)
        XCTAssertEqual(viewModel.state.inlineMessage, FortuneEntitlementError.insufficientJade(.oracle).localizedDescription)
    }

    @MainActor
    private func waitForAsyncState() async {
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
}
