import Foundation

struct CompatibilityReadingState: Equatable, Sendable {
    var scenario: MockScenario
    var activeTab: TodayPrimaryTab
    var title: String
    var subtitle: String
    var maleBirthDate: String
    var maleBirthHourLabel: String
    var femaleBirthDate: String
    var femaleBirthHourLabel: String
    var calculateButtonTitle: String
    var resultTitle: String
    var scoreText: String
    var summaryLines: [String]
    var inlineMessage: String?
}

enum CompatibilityReadingAction: Equatable, Sendable {
    case updateMaleBirthDate(String)
    case updateMaleBirthHour(String)
    case updateFemaleBirthDate(String)
    case updateFemaleBirthHour(String)
    case calculate
    case openTab(TodayPrimaryTab)
}
