import XCTest
@testable import FortuneTelling

final class BaziAnalysisTestRunner: XCTestCase {
    func testBaziAnalysisBuildsPillarsAndFiveElementsFromLocalKnowledge() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let service = LocalBaziAnalysisService(repository: repository)

        let payload = try await service.analyze(profile: .sample)
        let repeated = try await service.analyze(profile: .sample)

        XCTAssertEqual(payload.pillars.count, 4)
        XCTAssertEqual(payload.fiveElements.count, 5)
        XCTAssertFalse(payload.interpretation.isEmpty)
        XCTAssertTrue(payload.pillars.allSatisfy { !$0.heavenlyStem.isEmpty })
        XCTAssertTrue(payload.fiveElements.allSatisfy { $0.progress >= 0 && $0.progress <= 1 })
        XCTAssertEqual(payload, repeated)
    }

    func testBaziAnalysisRejectsInvalidBirthHour() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let service = LocalBaziAnalysisService(repository: repository)
        var invalidProfile = ProfileSnapshot.sample
        invalidProfile.birthHourLabel = "深夜"

        await XCTAssertThrowsErrorAsync(try await service.analyze(profile: invalidProfile)) { error in
            XCTAssertEqual(error as? BaziAnalysisServiceError, .invalidProfile)
        }
    }

    func testBaziAnalysisRejectsInvalidGender() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let service = LocalBaziAnalysisService(repository: repository)
        var invalidProfile = ProfileSnapshot.sample
        invalidProfile.gender = "未知"

        await XCTAssertThrowsErrorAsync(try await service.analyze(profile: invalidProfile)) { error in
            XCTAssertEqual(error as? BaziAnalysisServiceError, .invalidProfile)
        }
    }

    func testBaziAnalysisRejectsInvalidCalendarType() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let service = LocalBaziAnalysisService(repository: repository)
        var invalidProfile = ProfileSnapshot.sample
        invalidProfile.calendarType = "天文历"

        await XCTAssertThrowsErrorAsync(try await service.analyze(profile: invalidProfile)) { error in
            XCTAssertEqual(error as? BaziAnalysisServiceError, .invalidProfile)
        }
    }

    func testLunarBirthInputMatchesEquivalentSolarDate() throws {
        let lunarInput = FortuneBirthInput(
            birthDate: "2020-07-15",
            birthHourLabel: FortuneFieldCatalog.hourOptions[6],
            gender: "女",
            calendarType: "农历"
        )
        let solarInput = FortuneBirthInput(
            birthDate: "2020-09-02",
            birthHourLabel: FortuneFieldCatalog.hourOptions[6],
            gender: "女",
            calendarType: "公历"
        )

        let lunarAnalysis = try FortuneAlgorithmEngine.analyzeBazi(for: lunarInput)
        let solarAnalysis = try FortuneAlgorithmEngine.analyzeBazi(for: solarInput)

        XCTAssertEqual(lunarAnalysis.calendar.yearPillar, solarAnalysis.calendar.yearPillar)
        XCTAssertEqual(lunarAnalysis.calendar.monthPillar, solarAnalysis.calendar.monthPillar)
        XCTAssertEqual(lunarAnalysis.calendar.dayPillar, solarAnalysis.calendar.dayPillar)
        XCTAssertEqual(lunarAnalysis.calendar.hourPillar, solarAnalysis.calendar.hourPillar)
        XCTAssertEqual(lunarAnalysis.fiveElementScores, solarAnalysis.fiveElementScores)
    }

    func testBaziGoldenSampleMatchesExpectedPillarsAndPattern() throws {
        let analysis = try FortuneAlgorithmEngine.analyzeBazi(
            for: FortuneBirthInput(
                birthDate: "1998-08-16",
                birthHourLabel: "戌时 (19:00-21:00)",
                gender: "女",
                calendarType: "公历"
            )
        )
        let pillars = [
            analysis.calendar.yearPillar.label,
            analysis.calendar.monthPillar.label,
            analysis.calendar.dayPillar.label,
            analysis.calendar.hourPillar.label
        ]

        XCTAssertEqual(pillars, ["戊寅", "庚申", "乙未", "丙戌"])
        XCTAssertEqual(analysis.fiveElementScores["金"], 78)
        XCTAssertEqual(analysis.fiveElementScores["木"], 38)
        XCTAssertEqual(analysis.fiveElementScores["水"], 8)
        XCTAssertEqual(analysis.dayMasterStrengthLabel, "偏弱")
        XCTAssertEqual(analysis.favorableElements, ["木", "水"])
        XCTAssertEqual(analysis.resolvedPattern, "食神生财")
        XCTAssertEqual(analysis.patternCandidates.first?.label, analysis.resolvedPattern)
        XCTAssertTrue(analysis.scoreBreakdown.contains(where: { $0.label == "日主平衡" }))
        XCTAssertEqual(analysis.scoreBreakdown.first?.label, "金势")
    }

    func testBaziInsightRenderContextMatchesStructuredKnowledge() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let insights = try await repository.loadBaziKnowledge()
        let analysis = try FortuneAlgorithmEngine.analyzeBazi(
            for: FortuneBirthInput(
                birthDate: "1998-08-16",
                birthHourLabel: "戌时 (19:00-21:00)",
                gender: "女",
                calendarType: "公历"
            )
        )
        let renderContext = BaziInsightRenderContext.resolve(analysis: analysis, insights: insights)

        XCTAssertNotNil(renderContext.matchedInsight)
        XCTAssertEqual(renderContext.matchedInsight?.dominantElement, "木")
        XCTAssertTrue(renderContext.matchedInsight?.strengthLabels.contains(analysis.dayMasterStrengthLabel) == true)
        XCTAssertGreaterThan(renderContext.matchScore, 0)
        XCTAssertTrue(renderContext.matchBreakdown.contains(where: { $0.label == "主五行匹配" && $0.score > 0 }))
        XCTAssertTrue(renderContext.matchBreakdown.contains(where: { $0.label == "强弱匹配" && $0.score > 0 }))
    }

    func testLeapLunarBirthInputMatchesResolvedSolarDate() throws {
        let timezone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        let leapSolarDate = try XCTUnwrap(resolvedSolarDate(forLunarYear: 2020, month: 4, day: 1, isLeapMonth: true, timezone: timezone))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timezone
        formatter.dateFormat = "yyyy-MM-dd"

        let lunarInput = FortuneBirthInput(
            birthDate: "2020-04-01",
            birthHourLabel: FortuneFieldCatalog.hourOptions[6],
            gender: "女",
            calendarType: "农历",
            isLeapMonth: true,
            timezone: timezone
        )
        let solarInput = FortuneBirthInput(
            birthDate: formatter.string(from: leapSolarDate),
            birthHourLabel: FortuneFieldCatalog.hourOptions[6],
            gender: "女",
            calendarType: "公历",
            timezone: timezone
        )

        let lunarAnalysis = try FortuneAlgorithmEngine.analyzeBazi(for: lunarInput)
        let solarAnalysis = try FortuneAlgorithmEngine.analyzeBazi(for: solarInput)

        XCTAssertEqual(lunarAnalysis.calendar.yearPillar, solarAnalysis.calendar.yearPillar)
        XCTAssertEqual(lunarAnalysis.calendar.monthPillar, solarAnalysis.calendar.monthPillar)
        XCTAssertEqual(lunarAnalysis.calendar.dayPillar, solarAnalysis.calendar.dayPillar)
        XCTAssertEqual(lunarAnalysis.calendar.hourPillar, solarAnalysis.calendar.hourPillar)
        XCTAssertEqual(lunarAnalysis.fiveElementScores, solarAnalysis.fiveElementScores)
    }

    func testYearPillarChangesAcrossLiChunBoundary() throws {
        let beforeLiChun = try FortuneAlgorithmEngine.analyzeBazi(
            for: FortuneBirthInput(
                birthDate: "2020-02-03",
                birthHourLabel: FortuneFieldCatalog.hourOptions[6],
                gender: "男",
                calendarType: "公历"
            )
        )
        let afterLiChun = try FortuneAlgorithmEngine.analyzeBazi(
            for: FortuneBirthInput(
                birthDate: "2020-02-05",
                birthHourLabel: FortuneFieldCatalog.hourOptions[6],
                gender: "男",
                calendarType: "公历"
            )
        )

        XCTAssertEqual(beforeLiChun.calendar.yearPillar.label, "己亥")
        XCTAssertEqual(afterLiChun.calendar.yearPillar.label, "庚子")
        XCTAssertNotEqual(beforeLiChun.calendar.yearPillar, afterLiChun.calendar.yearPillar)
    }

    func testTrueSolarTimeLongitudeAdjustmentCanShiftHourPillar() throws {
        let westInput = FortuneBirthInput(
            birthDate: "1998-08-16",
            birthHourLabel: FortuneFieldCatalog.hourOptions[0],
            gender: "女",
            calendarType: "公历",
            location: FortuneLocation(longitude: 73.0, latitude: 39.0)
        )
        let eastInput = FortuneBirthInput(
            birthDate: "1998-08-16",
            birthHourLabel: FortuneFieldCatalog.hourOptions[0],
            gender: "女",
            calendarType: "公历",
            location: FortuneLocation(longitude: 135.0, latitude: 35.0)
        )

        let westAnalysis = try FortuneAlgorithmEngine.analyzeBazi(for: westInput)
        let eastAnalysis = try FortuneAlgorithmEngine.analyzeBazi(for: eastInput)
        let minuteDelta = abs(westAnalysis.calendar.trueSolarDate.timeIntervalSince(eastAnalysis.calendar.trueSolarDate)) / 60

        XCTAssertGreaterThan(minuteDelta, 200)
        XCTAssertNotEqual(westAnalysis.calendar.hourPillar, eastAnalysis.calendar.hourPillar)
    }

    @MainActor
    func testBaziViewModelConsumesOneJadeWhenCalculationSucceeds() async {
        let entitlement = InMemoryFortuneEntitlementService(jadeBalance: 3, isVIPActive: false)
        let viewModel = BaziAnalysisViewModel(
            service: MockBaziAnalysisService(),
            profileStore: InMemoryProfileStore(profile: nil),
            entitlementService: entitlement
        )

        viewModel.send(.updateBirthDate("2020-08-16"))
        viewModel.send(.updateBirthHour(FortuneFieldCatalog.hourOptions[4]))
        viewModel.send(.updateGender("女"))
        viewModel.send(.updateCalendar("公历"))
        viewModel.send(.calculate)

        try? await Task.sleep(nanoseconds: 250_000_000)

        let snapshot = await entitlement.loadSnapshot()
        XCTAssertEqual(snapshot.jadeBalance, 2)
        XCTAssertEqual(viewModel.state.scenario, .ideal)
    }

    private func resolvedSolarDate(
        forLunarYear year: Int,
        month: Int,
        day: Int,
        isLeapMonth: Bool,
        timezone: TimeZone
    ) -> Date? {
        var calendar = Calendar(identifier: .chinese)
        calendar.timeZone = timezone
        let cycle = chineseCycleComponents(forGregorianYear: year)
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = timezone
        components.era = cycle.era
        components.year = cycle.year
        components.month = month
        components.day = day
        components.isLeapMonth = isLeapMonth
        return calendar.date(from: components)
    }

    private func chineseCycleComponents(forGregorianYear year: Int) -> (era: Int, year: Int) {
        let absoluteChineseYear = year + 2697
        let quotient = absoluteChineseYear / 60
        let remainder = absoluteChineseYear % 60

        if remainder == 0 {
            return (max(1, quotient - 1), 60)
        }

        return (quotient, remainder)
    }

    private func XCTAssertThrowsErrorAsync<T>(
        _ expression: @autoclosure () async throws -> T,
        _ errorHandler: (Error) -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected expression to throw an error", file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
}
