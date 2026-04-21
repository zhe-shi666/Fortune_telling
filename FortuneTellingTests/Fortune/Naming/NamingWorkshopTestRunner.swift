import XCTest
@testable import FortuneTelling

final class NamingWorkshopTestRunner: XCTestCase {
    func testNamingSurnameInputSupportDoesNotSilentlyStripInvalidCharacters() {
        let invalid = NamingWorkshopInputSupport.normalizedSurnameInput("@#")

        XCTAssertEqual(invalid, "@#")
        XCTAssertFalse(NamingWorkshopInputSupport.isValidSurname(invalid))
        XCTAssertEqual(
            NamingWorkshopInputSupport.validationMessage(for: invalid),
            NamingWorkshopServiceError.invalidSurname.localizedDescription
        )
    }

    func testNamingServiceRespectsInputSurnameAndIsDeterministic() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let service = LocalNamingRecommendationService(repository: repository)

        let hour = FortuneFieldCatalog.hourOptions[4]
        let payload = try await service.recommendNames(for: "2020-08-16", birthHourLabel: hour, surname: "欧阳", gender: "女")
        let repeated = try await service.recommendNames(for: "2020-08-16", birthHourLabel: hour, surname: "欧阳", gender: "女")

        XCTAssertEqual(payload.candidates.count, 8)
        XCTAssertTrue(payload.candidates.allSatisfy { $0.title.hasPrefix("欧阳") })
        XCTAssertTrue(payload.candidates.allSatisfy { !$0.fiveElementSummary.isEmpty })
        XCTAssertEqual(payload, repeated)
    }

    func testNamingServiceRequiresBirthHourSelection() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let service = LocalNamingRecommendationService(repository: repository)

        do {
            _ = try await service.recommendNames(for: "2020-08-16", birthHourLabel: "", surname: "陈", gender: "女")
            XCTFail("Expected invalidBirthHour error")
        } catch let error as NamingWorkshopServiceError {
            XCTAssertEqual(error, .invalidBirthHour)
        }
    }

    func testNamingServiceRequiresGenderSelection() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let service = LocalNamingRecommendationService(repository: repository)

        do {
            _ = try await service.recommendNames(
                for: "2020-08-16",
                birthHourLabel: FortuneFieldCatalog.hourOptions[4],
                surname: "陈",
                gender: ""
            )
            XCTFail("Expected invalidGender error")
        } catch let error as NamingWorkshopServiceError {
            XCTAssertEqual(error, .invalidGender)
        }
    }

    func testNamingServiceRejectsInvalidSurname() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let service = LocalNamingRecommendationService(repository: repository)

        do {
            _ = try await service.recommendNames(for: "2020-08-16", birthHourLabel: FortuneFieldCatalog.hourOptions[4], surname: "Alex", gender: "男")
            XCTFail("Expected invalidSurname error")
        } catch let error as NamingWorkshopServiceError {
            XCTAssertEqual(error, .invalidSurname)
        }
    }

    func testNamingServiceUsesGenderToReorderCandidates() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let service = LocalNamingRecommendationService(repository: repository)
        let hour = FortuneFieldCatalog.hourOptions[4]

        let malePayload = try await service.recommendNames(
            for: "2020-08-16",
            birthHourLabel: hour,
            surname: "陈",
            gender: "男"
        )
        let femalePayload = try await service.recommendNames(
            for: "2020-08-16",
            birthHourLabel: hour,
            surname: "陈",
            gender: "女"
        )

        XCTAssertNotEqual(malePayload, femalePayload)
        XCTAssertNotEqual(malePayload.candidates.first?.title, femalePayload.candidates.first?.title)
        XCTAssertNotEqual(malePayload.candidates.map(\.title), femalePayload.candidates.map(\.title))
    }

    func testNamingServiceProducesDistributedScoresInsteadOfUniformTopScores() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let service = LocalNamingRecommendationService(repository: repository)

        let payload = try await service.recommendNames(
            for: "2020-08-16",
            birthHourLabel: FortuneFieldCatalog.hourOptions[4],
            surname: "陈",
            gender: "男"
        )
        let scores = payload.candidates.compactMap { candidate in
            Int(candidate.scoreText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
        }

        XCTAssertEqual(scores.count, payload.candidates.count)
        XCTAssertGreaterThan(Set(scores).count, 2)
        XCTAssertFalse(scores.allSatisfy { $0 == 99 })
        XCTAssertTrue(scores.allSatisfy { (68...98).contains($0) })
    }

    func testNamingGoldenSampleMatchesStructuredLexiconRanking() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let service = LocalNamingRecommendationService(repository: repository)
        let payload = try await service.recommendNames(
            for: "2020-08-16",
            birthHourLabel: FortuneFieldCatalog.hourOptions[4],
            surname: "欧阳",
            gender: "女"
        )

        XCTAssertEqual(payload.candidates.count, 8)
        XCTAssertEqual(
            payload.candidates.prefix(3).map(\.title),
            ["欧阳予宁", "欧阳星澜", "欧阳昭宁"]
        )
        XCTAssertEqual(
            payload.candidates.prefix(3).map(\.scoreText),
            ["得分 98", "得分 98", "得分 98"]
        )
    }

    func testNamingAlgorithmProducesStructuredScoreBreakdown() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let lexicon = try await repository.loadNamingKnowledge()
        let candidates = try FortuneAlgorithmEngine.recommendNames(
            for: FortuneBirthInput(
                birthDate: "2020-08-16",
                birthHourLabel: FortuneFieldCatalog.hourOptions[4],
                gender: "女",
                calendarType: "公历"
            ),
            surname: "欧阳",
            lexicon: lexicon,
            limit: 4
        )

        let first = try XCTUnwrap(candidates.first)
        let rendered = NamingRecommendationRenderAdapter.makeContent(from: first)
        let total = first.scoreBreakdown.reduce(0) { $0 + $1.score }

        XCTAssertFalse(first.scoreBreakdown.isEmpty)
        XCTAssertEqual(first.scoreBreakdown.first?.label, "基础分")
        XCTAssertTrue(first.scoreBreakdown.contains(where: { $0.label == "主五行贴合" }))
        XCTAssertTrue(first.scoreBreakdown.contains(where: { $0.label == "性别匹配" }))
        XCTAssertEqual(total, first.totalScore)
        XCTAssertTrue(rendered.fiveElementSummary.contains("五行与气质"))
    }

    @MainActor
    func testNamingViewModelPrependsNewlyGeneratedCandidates() async throws {
        let viewModel = NamingWorkshopViewModel(
            service: MockNamingRecommendationService(),
            profileStore: InMemoryProfileStore(profile: nil),
            favoritesStore: InMemoryNamingFavoritesStore(),
            entitlementService: InMemoryFortuneEntitlementService()
        )

        viewModel.send(.updateSurname("林"))
        viewModel.send(.updateGender("女"))
        viewModel.send(.updateBirthDate("2020-08-16"))
        viewModel.send(.updateBirthHour(FortuneFieldCatalog.hourOptions[4]))

        viewModel.send(.generate)
        try await Task.sleep(nanoseconds: 300_000_000)
        let firstBatch = viewModel.state.candidates.map(\.title)

        XCTAssertEqual(firstBatch.count, 2)

        viewModel.send(.generate)
        try await Task.sleep(nanoseconds: 300_000_000)
        let secondBatch = viewModel.state.candidates.map(\.title)

        XCTAssertEqual(secondBatch.count, 4)
        XCTAssertEqual(Array(secondBatch.suffix(firstBatch.count)), firstBatch)
        XCTAssertNotEqual(Array(secondBatch.prefix(firstBatch.count)), firstBatch)
    }

    @MainActor
    func testNamingViewModelConsumesOneJadeForEachGenerateAction() async throws {
        let entitlement = InMemoryFortuneEntitlementService(jadeBalance: 2, isVIPActive: false)
        let viewModel = NamingWorkshopViewModel(
            service: MockNamingRecommendationService(),
            profileStore: InMemoryProfileStore(profile: nil),
            favoritesStore: InMemoryNamingFavoritesStore(),
            entitlementService: entitlement
        )

        viewModel.send(.updateSurname("林"))
        viewModel.send(.updateGender("女"))
        viewModel.send(.updateBirthDate("2020-08-16"))
        viewModel.send(.updateBirthHour(FortuneFieldCatalog.hourOptions[4]))

        viewModel.send(.generate)
        try await Task.sleep(nanoseconds: 250_000_000)
        var snapshot = await entitlement.loadSnapshot()
        XCTAssertEqual(snapshot.jadeBalance, 1)

        viewModel.send(.generate)
        try await Task.sleep(nanoseconds: 250_000_000)
        snapshot = await entitlement.loadSnapshot()
        XCTAssertEqual(snapshot.jadeBalance, 0)
        XCTAssertEqual(viewModel.state.candidates.count, 4)
    }
}
