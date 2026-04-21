import XCTest
@testable import FortuneTelling

final class CompatibilityReadingTestRunner: XCTestCase {
    func testCompatibilityServiceGeneratesDeterministicSummaryLines() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let service = LocalCompatibilityReadingService(repository: repository)

        let male = ProfileSnapshot(
            profileId: "male",
            birthDate: "1992-03-16",
            birthHourLabel: FortuneFieldCatalog.hourOptions[2],
            gender: "男",
            calendarType: "公历",
            lastUpdatedAt: ""
        )
        let female = ProfileSnapshot(
            profileId: "female",
            birthDate: "1995-11-07",
            birthHourLabel: FortuneFieldCatalog.hourOptions[5],
            gender: "女",
            calendarType: "公历",
            lastUpdatedAt: ""
        )

        let payload = try await service.analyze(male: male, female: female)
        let repeated = try await service.analyze(male: male, female: female)

        XCTAssertTrue(payload.scoreText.hasSuffix("%"))
        XCTAssertEqual(payload.summaryLines.count, 4)
        XCTAssertTrue(payload.summaryLines[0].contains("合婚参考"))
        XCTAssertTrue(payload.summaryLines[0].contains("夫妻宫"))
        XCTAssertTrue(payload.summaryLines[1].contains("五行协同"))
        XCTAssertTrue(payload.summaryLines[2].contains("双方出生时辰") || payload.summaryLines[2].contains("双方出生时辰节律"))
        XCTAssertTrue(payload.summaryLines[3].contains("命盘细节"))
        XCTAssertTrue(payload.summaryLines[3].contains("本次分值参考"))
        XCTAssertEqual(payload, repeated)
    }

    func testCompatibilityServiceChangesExplanationForDifferentCharts() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let service = LocalCompatibilityReadingService(repository: repository)

        let pairA = (
            male: ProfileSnapshot(
                profileId: "male-a",
                birthDate: "1992-03-16",
                birthHourLabel: FortuneFieldCatalog.hourOptions[2],
                gender: "男",
                calendarType: "公历",
                lastUpdatedAt: ""
            ),
            female: ProfileSnapshot(
                profileId: "female-a",
                birthDate: "1995-11-07",
                birthHourLabel: FortuneFieldCatalog.hourOptions[5],
                gender: "女",
                calendarType: "公历",
                lastUpdatedAt: ""
            )
        )
        let pairB = (
            male: ProfileSnapshot(
                profileId: "male-b",
                birthDate: "1988-01-22",
                birthHourLabel: FortuneFieldCatalog.hourOptions[10],
                gender: "男",
                calendarType: "公历",
                lastUpdatedAt: ""
            ),
            female: ProfileSnapshot(
                profileId: "female-b",
                birthDate: "1999-09-09",
                birthHourLabel: FortuneFieldCatalog.hourOptions[1],
                gender: "女",
                calendarType: "公历",
                lastUpdatedAt: ""
            )
        )

        let payloadA = try await service.analyze(male: pairA.male, female: pairA.female)
        let payloadB = try await service.analyze(male: pairB.male, female: pairB.female)

        XCTAssertNotEqual(payloadA.summaryLines, payloadB.summaryLines)
        XCTAssertNotEqual(payloadA.scoreText, payloadB.scoreText)
    }

    func testCompatibilityGoldenSampleMatchesTaggedAnalysis() throws {
        let analysis = try FortuneAlgorithmEngine.analyzeCompatibility(
            male: FortuneBirthInput(
                birthDate: "1992-03-16",
                birthHourLabel: FortuneFieldCatalog.hourOptions[2],
                gender: "男",
                calendarType: "公历"
            ),
            female: FortuneBirthInput(
                birthDate: "1995-11-07",
                birthHourLabel: FortuneFieldCatalog.hourOptions[5],
                gender: "女",
                calendarType: "公历"
            )
        )

        XCTAssertEqual(analysis.score, 79)
        XCTAssertEqual(analysis.overallBand, "稳步磨合")
        XCTAssertEqual(analysis.marriagePalaceRelation, "平衡")
        XCTAssertEqual(analysis.relationTags, ["平衡", "三刑", "相生", "磨合", "稳步磨合"])
        XCTAssertEqual(analysis.focusKeywords, ["节奏", "协作", "边界", "压力", "长期计划"])
        XCTAssertEqual(
            analysis.scoreBreakdown.map(\.label),
            ["基础分", "喜用契合", "喜忌错位", "夫妻宫关系", "日主关系", "强弱平衡", "地支互动", "格局互动"]
        )
        XCTAssertEqual(analysis.scoreBreakdown.reduce(0) { $0 + $1.score }, analysis.score)
        XCTAssertEqual(analysis.sharedFavorableElements, ["金"])
        XCTAssertEqual(analysis.maleDayMasterElement, "金")
        XCTAssertEqual(analysis.femaleDayMasterElement, "水")
        XCTAssertEqual(analysis.maleStrengthLabel, "中和")
        XCTAssertEqual(analysis.femaleStrengthLabel, "偏弱")
        XCTAssertEqual(analysis.dayMasterRelation, "相生")
        XCTAssertFalse(analysis.isComplementary)
        XCTAssertEqual(analysis.malePattern, "伤官配印")
        XCTAssertEqual(analysis.femalePattern, "食神生财")
        XCTAssertEqual(
            analysis.branchSupportDetails,
            [
                "月柱地支卯与戌成六合，相关生活层面更容易达成默契",
                "日柱地支同为寅，该层面的节律更易同频"
            ]
        )
        XCTAssertEqual(
            analysis.branchConflictDetails,
            [
                "双方命局合看已成寅巳申三刑，关系里更容易在节奏推进与主导权上反复拉扯",
                "年柱地支申与亥相害，该层面的默契更容易被细碎摩擦消耗"
            ]
        )
        XCTAssertEqual(analysis.maleDominantTenGod, "伤官")
        XCTAssertEqual(analysis.femaleDominantTenGod, "七杀")
        XCTAssertEqual(
            analysis.supportMatches,
            [
                "双方喜用方向存在交集：金",
                "夫妻宫暂无明显强冲，适合从现实协作慢慢建立稳定感",
                "双方日主五行形成相生，彼此更容易提供支持"
            ]
        )
        XCTAssertEqual(
            analysis.conflictMatches,
            [
                "双方喜忌存在错位，日常相处更需要先定边界",
                "双方命局合看已成寅巳申三刑，关系里更容易在节奏推进与主导权上反复拉扯"
            ]
        )
    }

    func testCompatibilityTemplateRenderContextMatchesKnowledge() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let templates = try await repository.loadCompatibilityKnowledge()
        let analysis = try FortuneAlgorithmEngine.analyzeCompatibility(
            male: FortuneBirthInput(
                birthDate: "1992-03-16",
                birthHourLabel: FortuneFieldCatalog.hourOptions[2],
                gender: "男",
                calendarType: "公历"
            ),
            female: FortuneBirthInput(
                birthDate: "1995-11-07",
                birthHourLabel: FortuneFieldCatalog.hourOptions[5],
                gender: "女",
                calendarType: "公历"
            )
        )
        let renderContext = CompatibilityTemplateRenderContext.resolve(analysis: analysis, templates: templates)

        XCTAssertNotNil(renderContext.matchedTemplate)
        XCTAssertGreaterThan(renderContext.matchScore, 0)
        XCTAssertTrue(renderContext.matchBreakdown.contains(where: { $0.label == "分段命中" && $0.score > 0 }))
        XCTAssertTrue(renderContext.matchBreakdown.contains(where: { $0.label == "关系标签命中" && $0.score > 0 }))
    }

    func testCompatibilityAnalysisCanDetectMarriagePalaceHarmPair() throws {
        let male = try findBirthInput(dayBranch: "子")
        let female = try findBirthInput(dayBranch: "未")

        let analysis = try FortuneAlgorithmEngine.analyzeCompatibility(male: male, female: female)

        XCTAssertEqual(analysis.marriagePalaceRelation, "相害")
        XCTAssertTrue(analysis.relationTags.contains("相害"))
        XCTAssertTrue(analysis.conflictMatches.contains(where: { $0.contains("相害") }))
        XCTAssertTrue(
            analysis.scoreBreakdown.contains(where: {
                $0.label == "夫妻宫关系" && $0.score < 0 && $0.reason.contains("相害")
            })
        )
    }

    func testCompatibilityDetectsMarriagePalacePunishmentPair() throws {
        let male = try findBirthInput(dayBranch: "子")
        let female = try findBirthInput(dayBranch: "卯")

        let analysis = try FortuneAlgorithmEngine.analyzeCompatibility(male: male, female: female)

        XCTAssertEqual(analysis.marriagePalaceRelation, "相刑")
        XCTAssertTrue(analysis.relationTags.contains("相刑"))
        XCTAssertTrue(analysis.focusKeywords.contains("分寸"))
        XCTAssertTrue(analysis.conflictMatches.contains(where: { $0.contains("相刑") }))
        XCTAssertTrue(
            analysis.scoreBreakdown.contains(where: {
                $0.label == "夫妻宫关系" && $0.score < 0 && $0.reason.contains("相刑")
            })
        )
    }

    func testCompatibilityDetectsMarriagePalaceSelfPunishmentPair() throws {
        let male = try findBirthInput(dayBranch: "辰")
        let female = try findBirthInput(dayBranch: "辰")

        let analysis = try FortuneAlgorithmEngine.analyzeCompatibility(male: male, female: female)

        XCTAssertEqual(analysis.marriagePalaceRelation, "相刑")
        XCTAssertTrue(analysis.relationTags.contains("相刑"))
        XCTAssertTrue(analysis.conflictMatches.contains(where: { $0.contains("相刑") }))
        XCTAssertTrue(
            analysis.scoreBreakdown.contains(where: {
                $0.label == "夫妻宫关系" && $0.score < 0 && $0.reason.contains("相刑")
            })
        )
    }

    func testCompatibilityDetectsCrossChartTriplePunishment() throws {
        let male = try findBirthInput(containingBranches: ["寅", "巳"])
        let female = try findBirthInput(containingBranches: ["申"])

        let analysis = try FortuneAlgorithmEngine.analyzeCompatibility(male: male, female: female)

        XCTAssertTrue(analysis.branchConflictDetails.contains(where: { $0.contains("三刑") }))
        XCTAssertTrue(analysis.relationTags.contains("三刑"))
        XCTAssertTrue(analysis.focusKeywords.contains("压力"))
        XCTAssertTrue(
            analysis.scoreBreakdown.contains(where: {
                $0.label == "地支互动" && $0.score < 0 && $0.reason.contains("三刑")
            })
        )
    }

    @MainActor
    func testCompatibilityViewModelConsumesOneJadeWhenAnalysisSucceeds() async {
        let entitlement = InMemoryFortuneEntitlementService(jadeBalance: 2, isVIPActive: false)
        let viewModel = CompatibilityReadingViewModel(
            service: MockCompatibilityReadingService(),
            profileStore: InMemoryProfileStore(profile: nil),
            entitlementService: entitlement
        )

        viewModel.send(.updateMaleBirthDate("1992-03-16"))
        viewModel.send(.updateMaleBirthHour(FortuneFieldCatalog.hourOptions[2]))
        viewModel.send(.updateFemaleBirthDate("1995-11-07"))
        viewModel.send(.updateFemaleBirthHour(FortuneFieldCatalog.hourOptions[5]))
        viewModel.send(.calculate)

        try? await Task.sleep(nanoseconds: 250_000_000)

        let snapshot = await entitlement.loadSnapshot()
        XCTAssertEqual(snapshot.jadeBalance, 1)
        XCTAssertEqual(viewModel.state.scenario, .ideal)
        XCTAssertFalse(viewModel.state.summaryLines.isEmpty)
    }

    private func findBirthInput(dayBranch targetBranch: String) throws -> FortuneBirthInput {
        let calendar = Calendar(identifier: .gregorian)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "yyyy-MM-dd"

        guard var date = formatter.date(from: "1988-01-01") else {
            XCTFail("无法初始化测试日期")
            throw NSError(domain: "CompatibilityReadingTestRunner", code: 1)
        }

        for _ in 0..<2400 {
            let input = FortuneBirthInput(
                birthDate: formatter.string(from: date),
                birthHourLabel: FortuneFieldCatalog.hourOptions[0],
                gender: "男",
                calendarType: "公历"
            )
            let analysis = try FortuneAlgorithmEngine.analyzeBazi(for: input)
            if analysis.calendar.dayPillar.branch == targetBranch {
                return input
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else {
                break
            }
            date = nextDate
        }

        XCTFail("未找到目标日支 \(targetBranch) 的测试样例")
        throw NSError(domain: "CompatibilityReadingTestRunner", code: 2)
    }

    private func findBirthInput(containingBranches targetBranches: Set<String>) throws -> FortuneBirthInput {
        let calendar = Calendar(identifier: .gregorian)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "yyyy-MM-dd"

        guard var date = formatter.date(from: "1988-01-01") else {
            XCTFail("无法初始化测试日期")
            throw NSError(domain: "CompatibilityReadingTestRunner", code: 3)
        }

        for _ in 0..<2400 {
            let dateText = formatter.string(from: date)
            for hourLabel in FortuneFieldCatalog.hourOptions {
                let input = FortuneBirthInput(
                    birthDate: dateText,
                    birthHourLabel: hourLabel,
                    gender: "男",
                    calendarType: "公历"
                )
                let analysis = try FortuneAlgorithmEngine.analyzeBazi(for: input)
                let branches = Set([
                    analysis.calendar.yearPillar.branch,
                    analysis.calendar.monthPillar.branch,
                    analysis.calendar.dayPillar.branch,
                    analysis.calendar.hourPillar.branch
                ])
                if targetBranches.isSubset(of: branches) {
                    return input
                }
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else {
                break
            }
            date = nextDate
        }

        XCTFail("未找到包含支位 \(targetBranches.sorted().joined(separator: "、")) 的测试样例")
        throw NSError(domain: "CompatibilityReadingTestRunner", code: 4)
    }
}
