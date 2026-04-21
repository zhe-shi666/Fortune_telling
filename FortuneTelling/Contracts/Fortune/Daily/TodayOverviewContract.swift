import Foundation

enum TodayPrimaryTab: String, CaseIterable, Identifiable, Hashable, Sendable {
    case daily
    case analysis
    case compatibility
    case naming

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily:
            "今日"
        case .analysis:
            "八字"
        case .compatibility:
            "合婚"
        case .naming:
            "取名"
        }
    }

    var symbol: String {
        switch self {
        case .daily:
            "☀"
        case .analysis:
            "☯"
        case .compatibility:
            "⚜"
        case .naming:
            "✍"
        }
    }
}

struct TodayQuickActionLabels: Equatable, Sendable {
    var profileShortTitle: String
    var rechargeShortTitle: String
    var oracleButtonTitle: String
    var oracleButtonSymbol: String
}

struct TodayHeroContent: Equatable, Sendable {
    var title: String
    var subtitle: String
}

struct DailyStemBranchContent: Equatable, Sendable {
    var label: String
    var value: String
    var updateHint: String
}

struct ActivityGuidanceContent: Equatable, Sendable {
    var title: String
    var recommendedLine: String
    var cautionLine: String
}

struct OraclePreviewContent: Equatable, Sendable {
    var title: String
    var summary: String
}

struct OracleDetailContent: Equatable, Sendable {
    var title: String
    var category: String
    var body: String
    var adviceTitle: String
    var adviceBody: String
    var triggerHint: String
    var secondaryButtonTitle: String
    var primaryButtonTitle: String
}

struct ProfilePromptContent: Equatable, Sendable {
    var title: String
    var body: String
    var primaryButtonTitle: String
}

struct ErrorCardContent: Equatable, Sendable {
    var title: String
    var message: String
    var retryButtonTitle: String
}

struct TodayOverviewState: Equatable, Sendable {
    var scenario: MockScenario
    var quickActions: TodayQuickActionLabels
    var hero: TodayHeroContent
    var stemBranch: DailyStemBranchContent?
    var guidance: ActivityGuidanceContent?
    var oraclePreview: OraclePreviewContent?
    var oracleDetail: OracleDetailContent?
    var profilePrompt: ProfilePromptContent?
    var errorContent: ErrorCardContent?
    var tabs: [TodayPrimaryTab]
    var activeTab: TodayPrimaryTab
    var inlineMessage: String?
    var isOracleSheetPresented: Bool
    var isRefreshing: Bool
}

enum TodayOverviewAction: Equatable, Sendable {
    case openProfile
    case openRecharge
    case openTab(TodayPrimaryTab)
    case presentOracle(Bool)
    case retryLoad
}
