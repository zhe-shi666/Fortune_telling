import SwiftUI

enum AppRoute: Hashable {
    case profile
    case recharge
}

@MainActor
final class AppCoordinator: ObservableObject, TodayOverviewRouting, ProfileEditorRouting, BaziAnalysisRouting, NamingWorkshopRouting, CompatibilityReadingRouting, RechargeCenterRouting {
    @Published var path: [AppRoute] = []
    @Published var selectedTab: TodayPrimaryTab = .daily

    let dailyViewModel: TodayOverviewViewModel
    let profileViewModel: ProfileEditorViewModel
    let baziViewModel: BaziAnalysisViewModel
    let namingViewModel: NamingWorkshopViewModel
    let compatibilityViewModel: CompatibilityReadingViewModel
    let rechargeViewModel: RechargeCenterViewModel

    private let profileStore: any ProfileStoring
    private let entitlementService: any FortuneEntitlementServicing
    private let repository: any FortuneLocalRepositorying

    init(
        repository: any FortuneLocalRepositorying = SwiftDataFortuneRepository.shared,
        dailyService: (any DailyFortuneServicing)? = nil,
        baziService: (any BaziAnalysisServicing)? = nil,
        namingService: (any NamingRecommendationServicing)? = nil,
        compatibilityService: (any CompatibilityReadingServicing)? = nil,
        entitlementService: (any FortuneEntitlementServicing)? = nil,
        rechargeService: (any RechargeCenterServicing)? = nil,
        profileStore: (any ProfileStoring)? = nil,
        namingFavoritesStore: (any NamingFavoritesStoring)? = nil
    ) {
        self.repository = repository
        let resolvedProfileStore = profileStore ?? SwiftDataProfileStore(repository: repository)
        let resolvedEntitlementService = entitlementService ?? SwiftDataFortuneEntitlementService(repository: repository)
        let resolvedNamingFavoritesStore = namingFavoritesStore ?? SwiftDataNamingFavoritesStore(repository: repository)
        let resolvedDailyService = dailyService ?? LocalDailyFortuneService(repository: repository)
        let resolvedBaziService = baziService ?? LocalBaziAnalysisService(repository: repository)
        let resolvedNamingService = namingService ?? LocalNamingRecommendationService(repository: repository)
        let resolvedCompatibilityService = compatibilityService ?? LocalCompatibilityReadingService(repository: repository)
        let resolvedRechargeService = rechargeService ?? LocalRechargeCenterService(entitlementService: resolvedEntitlementService)

        self.profileStore = resolvedProfileStore
        self.entitlementService = resolvedEntitlementService
        self.dailyViewModel = TodayOverviewViewModel(
            service: resolvedDailyService,
            profileStore: resolvedProfileStore,
            entitlementService: resolvedEntitlementService
        )
        self.profileViewModel = ProfileEditorViewModel(profileStore: resolvedProfileStore)
        self.baziViewModel = BaziAnalysisViewModel(
            service: resolvedBaziService,
            profileStore: resolvedProfileStore,
            entitlementService: resolvedEntitlementService
        )
        self.namingViewModel = NamingWorkshopViewModel(
            service: resolvedNamingService,
            profileStore: resolvedProfileStore,
            favoritesStore: resolvedNamingFavoritesStore,
            entitlementService: resolvedEntitlementService
        )
        self.compatibilityViewModel = CompatibilityReadingViewModel(
            service: resolvedCompatibilityService,
            profileStore: resolvedProfileStore,
            entitlementService: resolvedEntitlementService
        )
        self.rechargeViewModel = RechargeCenterViewModel(service: resolvedRechargeService)

        self.dailyViewModel.router = self
        self.profileViewModel.router = self
        self.baziViewModel.router = self
        self.namingViewModel.router = self
        self.compatibilityViewModel.router = self
        self.rechargeViewModel.router = self

        Task {
            try? await repository.prepareIfNeeded()
        }
    }

    func openProfile() {
        path.append(.profile)
    }

    func openRecharge() {
        path.append(.recharge)
        Task {
            await rechargeViewModel.refresh()
        }
    }

    func openTab(_ tab: TodayPrimaryTab) {
        selectedTab = tab
        path.removeAll()
    }

    func closeProfileEditor(saved: Bool) {
        if !path.isEmpty {
            path.removeLast()
        }

        if saved {
            Task {
                await dailyViewModel.refresh()
                await baziViewModel.refresh()
                await namingViewModel.refresh()
                await compatibilityViewModel.refresh()
            }
        }
    }

    func closeRechargeCenter() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
}
