import Foundation
import Combine

@MainActor
protocol TodayOverviewRouting: AnyObject {
    func openProfile()
    func openRecharge()
    func openTab(_ tab: TodayPrimaryTab)
}

@MainActor
final class TodayOverviewViewModel: ObservableObject {
    @Published var state: TodayOverviewState
    weak var router: (any TodayOverviewRouting)?
    private let service: any DailyFortuneServicing
    private let profileStore: any ProfileStoring
    private let entitlementService: any FortuneEntitlementServicing
    private let nowProvider: @Sendable () -> Date
    private var hasLoaded = false

    init(
        service: any DailyFortuneServicing,
        profileStore: any ProfileStoring,
        entitlementService: any FortuneEntitlementServicing = InMemoryFortuneEntitlementService(),
        initialState: TodayOverviewState = TodayOverviewMockFactory.make(.loading),
        nowProvider: @escaping @Sendable () -> Date = { Date() },
        router: (any TodayOverviewRouting)? = nil
    ) {
        self.service = service
        self.profileStore = profileStore
        self.entitlementService = entitlementService
        self.state = initialState
        self.nowProvider = nowProvider
        self.router = router
    }

    func refreshIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await refresh()
    }

    func refresh() async {
        state = TodayOverviewMockFactory.makeLoading()

        do {
            guard let profile = try await profileStore.loadProfile() else {
                state = TodayOverviewMockFactory.makeEmpty()
                return
            }
            guard isValidProfile(profile) else {
                var next = TodayOverviewMockFactory.makeEmpty()
                next.inlineMessage = "请先补齐出生日期、时辰、性别与历法后，再查看今日参考。"
                state = next
                return
            }

            let payload = try await service.fetchDailyFortune(for: profile, on: nowProvider())
            state = TodayOverviewMockFactory.makeIdeal(from: payload)
        } catch is CancellationError {
            return
        } catch {
            state = TodayOverviewMockFactory.makeError(message: error.localizedDescription)
        }
    }

    func send(_ action: TodayOverviewAction) {
        switch action {
        case .openProfile:
            state.inlineMessage = nil
            router?.openProfile()
        case .openRecharge:
            state.inlineMessage = nil
            router?.openRecharge()
        case .openTab(let tab):
            guard tab != .daily else { return }
            state.inlineMessage = nil
            router?.openTab(tab)
        case .presentOracle(let isPresented):
            guard state.oracleDetail != nil else { return }
            if !isPresented {
                state.isOracleSheetPresented = false
                return
            }
            Task { await presentOracleIfPossible() }
        case .retryLoad:
            Task { await refresh() }
        }
    }

    private func presentOracleIfPossible() async {
        do {
            _ = try await entitlementService.consumeIfNeeded(for: .oracle)
            state.inlineMessage = nil
            state.isOracleSheetPresented = true
        } catch {
            state.inlineMessage = error.localizedDescription
            state.isOracleSheetPresented = false
        }
    }

    private func isValidProfile(_ profile: ProfileSnapshot) -> Bool {
        FortuneValidation.isCompleteBirthInput(
            birthDate: profile.birthDate,
            birthHourLabel: profile.birthHourLabel,
            gender: profile.gender,
            calendarType: profile.calendarType
        )
    }
}
