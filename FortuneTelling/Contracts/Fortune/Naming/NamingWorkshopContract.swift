import Foundation

struct NamingCandidateContent: Equatable, Sendable, Identifiable, Codable {
    var id: String
    var title: String
    var fiveElementSummary: String
    var scoreText: String
    var isFavorite: Bool
}

struct NamingFavoritesContent: Equatable, Sendable {
    var title: String
    var subtitle: String
    var emptyTitle: String
    var emptyBody: String
}

struct NamingWorkshopState: Equatable, Sendable {
    var scenario: MockScenario
    var activeTab: TodayPrimaryTab
    var title: String
    var subtitle: String
    var surnameLabel: String
    var surname: String
    var surnamePlaceholder: String
    var genderLabel: String
    var gender: String
    var genderPlaceholder: String
    var birthDateLabel: String
    var birthDate: String
    var birthDatePlaceholder: String
    var birthHourLabel: String
    var birthHourPlaceholder: String
    var requiredBadge: String
    var generateButtonTitle: String
    var clearButtonTitle: String
    var favoritesButtonTitle: String
    var recommendationsTitle: String
    var candidates: [NamingCandidateContent]
    var favorites: [NamingCandidateContent]
    var favoritesContent: NamingFavoritesContent
    var isFavoritesPresented: Bool
    var inlineMessage: String?
    var toastMessage: String?
}

enum NamingWorkshopAction: Equatable, Sendable {
    case updateSurname(String)
    case updateGender(String)
    case updateBirthDate(String)
    case updateBirthHour(String)
    case generate
    case clearRecommendations
    case toggleFavorite(String)
    case presentFavorites(Bool)
    case openTab(TodayPrimaryTab)
}
