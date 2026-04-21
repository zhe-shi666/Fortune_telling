import Foundation

struct BaziPillarContent: Equatable, Sendable {
    var title: String
    var heavenlyStem: String
    var earthlyBranch: String
}

struct FiveElementMeterContent: Equatable, Sendable {
    var element: String
    var scoreText: String
    var progress: Double
    var tintHex: UInt32
}

struct BaziEmptyContent: Equatable, Sendable {
    var title: String
    var body: String
    var primaryButtonTitle: String
}

struct BaziErrorContent: Equatable, Sendable {
    var title: String
    var message: String
    var retryButtonTitle: String
}

struct BaziAnalysisState: Equatable, Sendable {
    var scenario: MockScenario
    var activeTab: TodayPrimaryTab
    var title: String
    var subtitle: String
    var formTitle: String
    var formCaption: String
    var birthDate: String
    var birthHourLabel: String
    var gender: String
    var calendarType: String
    var isLeapMonth: Bool
    var calculateButtonTitle: String
    var resultTitle: String
    var resultCaption: String
    var pillars: [BaziPillarContent]
    var fiveElements: [FiveElementMeterContent]
    var interpretation: String
    var inlineMessage: String?
    var emptyContent: BaziEmptyContent?
    var errorContent: BaziErrorContent?
}

enum BaziAnalysisAction: Equatable, Sendable {
    case updateBirthDate(String)
    case updateBirthHour(String)
    case updateGender(String)
    case updateCalendar(String)
    case updateLeapMonth(Bool)
    case calculate
    case retry
    case openTab(TodayPrimaryTab)
}
