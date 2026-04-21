import XCTest
@testable import FortuneTelling

final class ProfileEditorTestRunner: XCTestCase {
    func testBirthDateSupportKeepsSelectedCivilDate() {
        let selectedDate = FortuneBirthDateSupport.date(year: 2020, month: 8, day: 12)
        let storedText = FortuneBirthDateSupport.storageFormatter.string(from: selectedDate)

        XCTAssertEqual(storedText, "2020-08-12")
    }

    func testSwiftDataProfileStoreRoundTripsProfile() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let store = SwiftDataProfileStore(repository: repository)
        let profile = ProfileSnapshot(
            profileId: "profile-main",
            birthDate: "2020-04-01",
            birthHourLabel: FortuneFieldCatalog.hourOptions[4],
            gender: "女",
            calendarType: "农历",
            isLeapMonth: true,
            lastUpdatedAt: "2026-04-19T00:00:00Z"
        )

        try await store.saveProfile(profile)
        let loaded = try await store.loadProfile()

        XCTAssertEqual(loaded, profile)
    }

    @MainActor
    func testProfileEditorSaveShowsRefreshMessage() async throws {
        let store = InMemoryProfileStore(profile: nil)
        let viewModel = ProfileEditorViewModel(profileStore: store)

        viewModel.send(.updateBirthDate("2020-08-12"))
        viewModel.send(.updateBirthHour(FortuneFieldCatalog.hourOptions[4]))
        viewModel.send(.updateGender("女"))
        viewModel.send(.updateCalendar("公历"))
        viewModel.send(.save)

        try await Task.sleep(nanoseconds: 150_000_000)

        XCTAssertEqual(viewModel.state.validationMessage, FortuneProductCopy.profileRefreshMessage)
    }
}
