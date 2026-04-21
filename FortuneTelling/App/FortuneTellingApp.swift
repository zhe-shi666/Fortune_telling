import SwiftUI

@main
struct FortuneTellingApp: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            RootNavigationView(coordinator: coordinator)
        }
    }
}

private struct RootNavigationView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            primaryScreen
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .profile:
                        ProfileEditorView(viewModel: coordinator.profileViewModel)
                    case .recharge:
                        RechargeCenterView(viewModel: coordinator.rechargeViewModel)
                    }
                }
        }
    }

    @ViewBuilder
    private var primaryScreen: some View {
        switch coordinator.selectedTab {
        case .daily:
            TodayOverviewView(viewModel: coordinator.dailyViewModel)
        case .analysis:
            BaziAnalysisView(viewModel: coordinator.baziViewModel)
        case .compatibility:
            CompatibilityReadingView(viewModel: coordinator.compatibilityViewModel)
        case .naming:
            NamingWorkshopView(viewModel: coordinator.namingViewModel)
        }
    }
}
