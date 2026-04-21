import Foundation
import SwiftData

struct ProfileSnapshot: Equatable, Sendable, Codable {
    var profileId: String
    var birthDate: String
    var birthHourLabel: String
    var gender: String
    var calendarType: String
    var isLeapMonth: Bool
    var lastUpdatedAt: String

    init(
        profileId: String,
        birthDate: String,
        birthHourLabel: String,
        gender: String,
        calendarType: String,
        isLeapMonth: Bool = false,
        lastUpdatedAt: String
    ) {
        self.profileId = profileId
        self.birthDate = birthDate
        self.birthHourLabel = birthHourLabel
        self.gender = gender
        self.calendarType = calendarType
        self.isLeapMonth = isLeapMonth
        self.lastUpdatedAt = lastUpdatedAt
    }

    enum CodingKeys: String, CodingKey {
        case profileId
        case birthDate
        case birthHourLabel
        case gender
        case calendarType
        case isLeapMonth
        case lastUpdatedAt
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profileId = try container.decode(String.self, forKey: .profileId)
        birthDate = try container.decode(String.self, forKey: .birthDate)
        birthHourLabel = try container.decode(String.self, forKey: .birthHourLabel)
        gender = try container.decode(String.self, forKey: .gender)
        calendarType = try container.decode(String.self, forKey: .calendarType)
        isLeapMonth = try container.decodeIfPresent(Bool.self, forKey: .isLeapMonth) ?? false
        lastUpdatedAt = try container.decode(String.self, forKey: .lastUpdatedAt)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(profileId, forKey: .profileId)
        try container.encode(birthDate, forKey: .birthDate)
        try container.encode(birthHourLabel, forKey: .birthHourLabel)
        try container.encode(gender, forKey: .gender)
        try container.encode(calendarType, forKey: .calendarType)
        try container.encode(isLeapMonth, forKey: .isLeapMonth)
        try container.encode(lastUpdatedAt, forKey: .lastUpdatedAt)
    }

    static let sample = ProfileSnapshot(
        profileId: "profile-main",
        birthDate: "1998-08-16",
        birthHourLabel: "戌时 (19:00-21:00)",
        gender: "女",
        calendarType: "公历",
        isLeapMonth: false,
        lastUpdatedAt: "2026-04-18T09:41:00Z"
    )
}

protocol ProfileStoring: Sendable {
    func loadProfile() async throws -> ProfileSnapshot?
    func saveProfile(_ profile: ProfileSnapshot) async throws
}

actor InMemoryProfileStore: ProfileStoring {
    private var profile: ProfileSnapshot?

    init(profile: ProfileSnapshot? = .sample) {
        self.profile = profile
    }

    func loadProfile() async throws -> ProfileSnapshot? {
        profile
    }

    func saveProfile(_ profile: ProfileSnapshot) async throws {
        self.profile = profile
    }
}

actor UserDefaultsProfileStore: ProfileStoring {
    private let suiteName: String?
    private let storageKey: String

    init(
        suiteName: String? = nil,
        storageKey: String = "fortune.profile.snapshot.v1"
    ) {
        self.suiteName = suiteName
        self.storageKey = storageKey
    }

    func loadProfile() async throws -> ProfileSnapshot? {
        guard let data = defaults().data(forKey: storageKey) else {
            return nil
        }

        return try JSONDecoder().decode(ProfileSnapshot.self, from: data)
    }

    func saveProfile(_ profile: ProfileSnapshot) async throws {
        let data = try JSONEncoder().encode(profile)
        defaults().set(data, forKey: storageKey)
    }

    func clear() async {
        defaults().removeObject(forKey: storageKey)
    }

    private func defaults() -> UserDefaults {
        guard let suiteName, let defaults = UserDefaults(suiteName: suiteName) else {
            return .standard
        }

        return defaults
    }
}

struct DailyGuidanceKnowledge: Equatable, Sendable, Codable {
    var ruleId: String
    var primaryElement: String
    var favorableLevels: [String]
    var heroSubtitle: String
    var rhythmDescriptor: String
    var recommendations: [String]
    var cautions: [String]
    var oracleCategory: String
    var oracleHead: String
    var oracleBody: String
    var adviceKeyword: String
    var supportKeywords: [String]
    var riskKeywords: [String]
    var adviceScenes: [String]
}

struct BaziInsightKnowledge: Equatable, Sendable, Codable {
    var insightId: String
    var dominantElement: String
    var supportElement: String
    var strengthLabels: [String]
    var focusTags: [String]
    var interpretationTemplate: String
    var advisoryFocus: String
}

struct NamingSurnameKnowledge: Equatable, Sendable, Codable {
    var value: String
    var weight: Int
    var styleTags: [String]
}

struct NamingGivenNameKnowledge: Equatable, Sendable, Codable {
    var entryId: String
    var leading: String
    var trailing: String
    var element: String
    var supportElement: String
    var mood: String
    var genderAffinity: String
    var semanticTags: [String]
    var styleLabel: String
    var commonnessRank: Int
    var writingComplexity: Int
    var weight: Int
    var notes: String
}

struct NamingLexiconKnowledge: Equatable, Sendable, Codable {
    var surnameEntries: [NamingSurnameKnowledge]
    var givenNames: [NamingGivenNameKnowledge]

    var surnames: [String] {
        surnameEntries.map(\.value)
    }
}

struct CompatibilityTemplateKnowledge: Equatable, Sendable, Codable {
    var templateId: String
    var minimumScore: Int
    var maximumScore: Int
    var scoreBandKey: String
    var bandLabel: String
    var relationTags: [String]
    var focusKeywords: [String]
    var sharedTone: String
    var nearRhythmLine: String
    var farRhythmLine: String
    var highScoreCaution: String
    var baseCaution: String
}

struct FortuneKnowledgeCatalog: Equatable, Sendable, Codable {
    var schemaVersion: Int
    var dailyGuidance: [DailyGuidanceKnowledge]
    var baziInsights: [BaziInsightKnowledge]
    var namingLexicon: NamingLexiconKnowledge
    var compatibilityTemplates: [CompatibilityTemplateKnowledge]
}

enum LocalKnowledgeBaseError: LocalizedError, Equatable {
    case missingResource
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .missingResource:
            "本地知识库资源缺失，暂时无法完成内容加载。"
        case .decodeFailed:
            "本地知识库解析失败，请检查资源格式。"
        }
    }
}

protocol FortuneLocalRepositorying: Sendable {
    func prepareIfNeeded() async throws
    func loadProfile() async throws -> ProfileSnapshot?
    func saveProfile(_ profile: ProfileSnapshot) async throws
    func loadEntitlement() async throws -> FortuneEntitlementSnapshot
    func consumeEntitlement(for feature: FortuneUsageFeature) async throws -> FortuneEntitlementSnapshot
    func grantJade(_ amount: Int) async throws -> FortuneEntitlementSnapshot
    func setVIPActive(_ isActive: Bool) async throws -> FortuneEntitlementSnapshot
    func loadFavorites() async throws -> [NamingCandidateContent]
    func toggleFavorite(_ candidate: NamingCandidateContent) async throws -> [NamingCandidateContent]
    func loadDailyKnowledge() async throws -> [DailyGuidanceKnowledge]
    func loadBaziKnowledge() async throws -> [BaziInsightKnowledge]
    func loadNamingKnowledge() async throws -> NamingLexiconKnowledge
    func loadCompatibilityKnowledge() async throws -> [CompatibilityTemplateKnowledge]
}

@Model
final class LocalProfileEntity {
    @Attribute(.unique) var profileId: String
    var birthDate: String
    var birthHourLabel: String
    var gender: String
    var calendarType: String
    var lastUpdatedAt: String

    init(
        profileId: String,
        birthDate: String,
        birthHourLabel: String,
        gender: String,
        calendarType: String,
        lastUpdatedAt: String
    ) {
        self.profileId = profileId
        self.birthDate = birthDate
        self.birthHourLabel = birthHourLabel
        self.gender = gender
        self.calendarType = calendarType
        self.lastUpdatedAt = lastUpdatedAt
    }
}

@Model
final class LocalProfileCalendarMetaEntity {
    @Attribute(.unique) var profileId: String
    var isLeapMonth: Bool

    init(profileId: String, isLeapMonth: Bool = false) {
        self.profileId = profileId
        self.isLeapMonth = isLeapMonth
    }
}

@Model
final class LocalEntitlementEntity {
    @Attribute(.unique) var walletId: String
    var jadeBalance: Int
    var isVIPActive: Bool

    init(walletId: String, jadeBalance: Int, isVIPActive: Bool) {
        self.walletId = walletId
        self.jadeBalance = jadeBalance
        self.isVIPActive = isVIPActive
    }
}

@Model
final class LocalNamingFavoriteEntity {
    @Attribute(.unique) var candidateId: String
    var title: String
    var fiveElementSummary: String
    var scoreText: String
    var createdAt: Date

    init(
        candidateId: String,
        title: String,
        fiveElementSummary: String,
        scoreText: String,
        createdAt: Date = .now
    ) {
        self.candidateId = candidateId
        self.title = title
        self.fiveElementSummary = fiveElementSummary
        self.scoreText = scoreText
        self.createdAt = createdAt
    }
}

@Model
final class LocalDailyGuidanceEntity {
    @Attribute(.unique) var ruleId: String
    var heroSubtitle: String
    var rhythmDescriptor: String
    var recommendationsCSV: String
    var cautionsCSV: String
    var oracleHead: String
    var oracleBody: String
    var adviceKeyword: String

    init(
        ruleId: String,
        heroSubtitle: String,
        rhythmDescriptor: String,
        recommendationsCSV: String,
        cautionsCSV: String,
        oracleHead: String,
        oracleBody: String,
        adviceKeyword: String
    ) {
        self.ruleId = ruleId
        self.heroSubtitle = heroSubtitle
        self.rhythmDescriptor = rhythmDescriptor
        self.recommendationsCSV = recommendationsCSV
        self.cautionsCSV = cautionsCSV
        self.oracleHead = oracleHead
        self.oracleBody = oracleBody
        self.adviceKeyword = adviceKeyword
    }
}

@Model
final class LocalBaziInsightEntity {
    @Attribute(.unique) var dominantElement: String
    var supportElement: String
    var interpretationTemplate: String

    init(dominantElement: String, supportElement: String, interpretationTemplate: String) {
        self.dominantElement = dominantElement
        self.supportElement = supportElement
        self.interpretationTemplate = interpretationTemplate
    }
}

@Model
final class LocalNamingLexiconEntity {
    @Attribute(.unique) var entryId: String
    var kind: String
    var primaryText: String
    var secondaryText: String
    var element: String
    var supportElement: String
    var mood: String
    var weight: Int

    init(
        entryId: String,
        kind: String,
        primaryText: String,
        secondaryText: String = "",
        element: String = "",
        supportElement: String = "",
        mood: String = "",
        weight: Int = 0
    ) {
        self.entryId = entryId
        self.kind = kind
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.element = element
        self.supportElement = supportElement
        self.mood = mood
        self.weight = weight
    }
}

@Model
final class LocalCompatibilityTemplateEntity {
    @Attribute(.unique) var templateId: String
    var minimumScore: Int
    var maximumScore: Int
    var bandLabel: String
    var sharedTone: String
    var nearRhythmLine: String
    var farRhythmLine: String
    var highScoreCaution: String
    var baseCaution: String

    init(
        templateId: String,
        minimumScore: Int,
        maximumScore: Int,
        bandLabel: String,
        sharedTone: String,
        nearRhythmLine: String,
        farRhythmLine: String,
        highScoreCaution: String,
        baseCaution: String
    ) {
        self.templateId = templateId
        self.minimumScore = minimumScore
        self.maximumScore = maximumScore
        self.bandLabel = bandLabel
        self.sharedTone = sharedTone
        self.nearRhythmLine = nearRhythmLine
        self.farRhythmLine = farRhythmLine
        self.highScoreCaution = highScoreCaution
        self.baseCaution = baseCaution
    }
}

@Model
final class LocalKnowledgeSeedEntity {
    @Attribute(.unique) var seedKey: String
    var version: Int
    var updatedAt: Date

    init(seedKey: String, version: Int, updatedAt: Date = .now) {
        self.seedKey = seedKey
        self.version = version
        self.updatedAt = updatedAt
    }
}

@Model
final class LocalKnowledgeCatalogVersionEntity {
    @Attribute(.unique) var catalogKey: String
    var schemaVersion: Int
    var importedAt: Date

    init(catalogKey: String, schemaVersion: Int, importedAt: Date = .now) {
        self.catalogKey = catalogKey
        self.schemaVersion = schemaVersion
        self.importedAt = importedAt
    }
}

@Model
final class LocalDailyGuidanceRuleEntity {
    @Attribute(.unique) var ruleId: String
    var primaryElement: String
    var favorableLevelsCSV: String
    var heroSubtitle: String
    var rhythmDescriptor: String
    var recommendationsCSV: String
    var cautionsCSV: String
    var oracleCategory: String
    var oracleHead: String
    var oracleBody: String
    var adviceKeyword: String
    var supportKeywordsCSV: String
    var riskKeywordsCSV: String
    var adviceScenesCSV: String

    init(
        ruleId: String,
        primaryElement: String,
        favorableLevelsCSV: String,
        heroSubtitle: String,
        rhythmDescriptor: String,
        recommendationsCSV: String,
        cautionsCSV: String,
        oracleCategory: String,
        oracleHead: String,
        oracleBody: String,
        adviceKeyword: String,
        supportKeywordsCSV: String,
        riskKeywordsCSV: String,
        adviceScenesCSV: String
    ) {
        self.ruleId = ruleId
        self.primaryElement = primaryElement
        self.favorableLevelsCSV = favorableLevelsCSV
        self.heroSubtitle = heroSubtitle
        self.rhythmDescriptor = rhythmDescriptor
        self.recommendationsCSV = recommendationsCSV
        self.cautionsCSV = cautionsCSV
        self.oracleCategory = oracleCategory
        self.oracleHead = oracleHead
        self.oracleBody = oracleBody
        self.adviceKeyword = adviceKeyword
        self.supportKeywordsCSV = supportKeywordsCSV
        self.riskKeywordsCSV = riskKeywordsCSV
        self.adviceScenesCSV = adviceScenesCSV
    }
}

@Model
final class LocalBaziInsightRuleEntity {
    @Attribute(.unique) var insightId: String
    var dominantElement: String
    var supportElement: String
    var strengthLabelsCSV: String
    var focusTagsCSV: String
    var interpretationTemplate: String
    var advisoryFocus: String

    init(
        insightId: String,
        dominantElement: String,
        supportElement: String,
        strengthLabelsCSV: String,
        focusTagsCSV: String,
        interpretationTemplate: String,
        advisoryFocus: String
    ) {
        self.insightId = insightId
        self.dominantElement = dominantElement
        self.supportElement = supportElement
        self.strengthLabelsCSV = strengthLabelsCSV
        self.focusTagsCSV = focusTagsCSV
        self.interpretationTemplate = interpretationTemplate
        self.advisoryFocus = advisoryFocus
    }
}

@Model
final class LocalNamingSurnameLexiconEntity {
    @Attribute(.unique) var entryId: String
    var value: String
    var weight: Int
    var styleTagsCSV: String

    init(entryId: String, value: String, weight: Int, styleTagsCSV: String) {
        self.entryId = entryId
        self.value = value
        self.weight = weight
        self.styleTagsCSV = styleTagsCSV
    }
}

@Model
final class LocalNamingGivenNameLexiconEntity {
    @Attribute(.unique) var entryId: String
    var leading: String
    var trailing: String
    var element: String
    var supportElement: String
    var mood: String
    var genderAffinity: String
    var semanticTagsCSV: String
    var styleLabel: String
    var commonnessRank: Int
    var writingComplexity: Int
    var weight: Int
    var notes: String

    init(
        entryId: String,
        leading: String,
        trailing: String,
        element: String,
        supportElement: String,
        mood: String,
        genderAffinity: String,
        semanticTagsCSV: String,
        styleLabel: String,
        commonnessRank: Int,
        writingComplexity: Int,
        weight: Int,
        notes: String
    ) {
        self.entryId = entryId
        self.leading = leading
        self.trailing = trailing
        self.element = element
        self.supportElement = supportElement
        self.mood = mood
        self.genderAffinity = genderAffinity
        self.semanticTagsCSV = semanticTagsCSV
        self.styleLabel = styleLabel
        self.commonnessRank = commonnessRank
        self.writingComplexity = writingComplexity
        self.weight = weight
        self.notes = notes
    }
}

@Model
final class LocalCompatibilityGuidanceTemplateEntity {
    @Attribute(.unique) var templateId: String
    var minimumScore: Int
    var maximumScore: Int
    var scoreBandKey: String
    var bandLabel: String
    var relationTagsCSV: String
    var focusKeywordsCSV: String
    var sharedTone: String
    var nearRhythmLine: String
    var farRhythmLine: String
    var highScoreCaution: String
    var baseCaution: String

    init(
        templateId: String,
        minimumScore: Int,
        maximumScore: Int,
        scoreBandKey: String,
        bandLabel: String,
        relationTagsCSV: String,
        focusKeywordsCSV: String,
        sharedTone: String,
        nearRhythmLine: String,
        farRhythmLine: String,
        highScoreCaution: String,
        baseCaution: String
    ) {
        self.templateId = templateId
        self.minimumScore = minimumScore
        self.maximumScore = maximumScore
        self.scoreBandKey = scoreBandKey
        self.bandLabel = bandLabel
        self.relationTagsCSV = relationTagsCSV
        self.focusKeywordsCSV = focusKeywordsCSV
        self.sharedTone = sharedTone
        self.nearRhythmLine = nearRhythmLine
        self.farRhythmLine = farRhythmLine
        self.highScoreCaution = highScoreCaution
        self.baseCaution = baseCaution
    }
}

actor SwiftDataFortuneRepository: FortuneLocalRepositorying {
    private enum Constants {
        static let catalogKey = "fortune.local.knowledge.catalog"
        static let walletId = "wallet-main"
        static let defaultJadeBalance = 1_288
        static let profileStorageKey = "fortune.profile.snapshot.v1"
        static let favoritesStorageKey = "fortune.naming.favorites.v1"
        static let jadeBalanceKey = "fortune.entitlement.jade.balance.v1"
        static let vipActiveKey = "fortune.entitlement.vip.active.v1"
    }

    static let shared = SwiftDataFortuneRepository()

    private static let schema = Schema([
        LocalProfileEntity.self,
        LocalProfileCalendarMetaEntity.self,
        LocalEntitlementEntity.self,
        LocalNamingFavoriteEntity.self,
        LocalDailyGuidanceEntity.self,
        LocalBaziInsightEntity.self,
        LocalNamingLexiconEntity.self,
        LocalCompatibilityTemplateEntity.self,
        LocalKnowledgeSeedEntity.self,
        LocalKnowledgeCatalogVersionEntity.self,
        LocalDailyGuidanceRuleEntity.self,
        LocalBaziInsightRuleEntity.self,
        LocalNamingSurnameLexiconEntity.self,
        LocalNamingGivenNameLexiconEntity.self,
        LocalCompatibilityGuidanceTemplateEntity.self
    ])

    private static func makeContainer(inMemory: Bool) -> ModelContainer {
        do {
            let configuration: ModelConfiguration
            if inMemory {
                configuration = ModelConfiguration(
                    "FortuneLocalMemoryStore",
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
            } else {
                let applicationSupportURL = try FileManager.default.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
                let storeURL = applicationSupportURL.appendingPathComponent(
                    "FortuneLocalStore.store",
                    conformingTo: .data
                )
                configuration = ModelConfiguration(
                    "FortuneLocalStore",
                    schema: schema,
                    url: storeURL
                )
            }
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    nonisolated static func makeInMemoryRepository() -> SwiftDataFortuneRepository {
        let defaults = UserDefaults(suiteName: "fortune.tests.\(UUID().uuidString)") ?? .standard
        return SwiftDataFortuneRepository(
            container: makeContainer(inMemory: true),
            legacyDefaults: defaults
        )
    }

    private let container: ModelContainer
    private let legacyDefaults: UserDefaults
    private var hasPrepared = false

    init(
        container: ModelContainer = makeContainer(inMemory: false),
        legacyDefaults: UserDefaults = .standard
    ) {
        self.container = container
        self.legacyDefaults = legacyDefaults
    }

    func prepareIfNeeded() async throws {
        guard !hasPrepared else { return }

        let context = ModelContext(container)
        try syncKnowledgeCatalogIfNeeded(in: context)
        try migrateLegacyProfileIfNeeded(in: context)
        try migrateLegacyEntitlementIfNeeded(in: context)
        try migrateLegacyFavoritesIfNeeded(in: context)
        try ensureEntitlementExists(in: context)

        if context.hasChanges {
            try context.save()
        }

        hasPrepared = true
    }

    func loadProfile() async throws -> ProfileSnapshot? {
        try await prepareIfNeeded()
        let context = ModelContext(container)
        guard let entity = try fetchFirst(LocalProfileEntity.self, in: context) else {
            return nil
        }
        return profileSnapshot(from: entity, in: context)
    }

    func saveProfile(_ profile: ProfileSnapshot) async throws {
        try await prepareIfNeeded()
        let context = ModelContext(container)
        if let entity = try fetchFirst(LocalProfileEntity.self, in: context) {
            entity.profileId = profile.profileId
            entity.birthDate = profile.birthDate
            entity.birthHourLabel = profile.birthHourLabel
            entity.gender = profile.gender
            entity.calendarType = profile.calendarType
            entity.lastUpdatedAt = profile.lastUpdatedAt
        } else {
            context.insert(
                LocalProfileEntity(
                    profileId: profile.profileId,
                    birthDate: profile.birthDate,
                    birthHourLabel: profile.birthHourLabel,
                    gender: profile.gender,
                    calendarType: profile.calendarType,
                    lastUpdatedAt: profile.lastUpdatedAt
                )
            )
        }

        if let meta = try profileCalendarMetaEntity(for: profile.profileId, in: context) {
            meta.isLeapMonth = profile.isLeapMonth
        } else {
            context.insert(LocalProfileCalendarMetaEntity(profileId: profile.profileId, isLeapMonth: profile.isLeapMonth))
        }
        try context.save()
    }

    func loadEntitlement() async throws -> FortuneEntitlementSnapshot {
        try await prepareIfNeeded()
        let context = ModelContext(container)
        let entity = try entitlementEntity(in: context)
        return FortuneEntitlementSnapshot(jadeBalance: entity.jadeBalance, isVIPActive: entity.isVIPActive)
    }

    func consumeEntitlement(for feature: FortuneUsageFeature) async throws -> FortuneEntitlementSnapshot {
        try await prepareIfNeeded()
        let context = ModelContext(container)
        let entity = try entitlementEntity(in: context)

        if entity.isVIPActive {
            return FortuneEntitlementSnapshot(jadeBalance: entity.jadeBalance, isVIPActive: true)
        }
        guard entity.jadeBalance > 0 else {
            throw FortuneEntitlementError.insufficientJade(feature)
        }

        entity.jadeBalance -= 1
        try context.save()
        return FortuneEntitlementSnapshot(jadeBalance: entity.jadeBalance, isVIPActive: entity.isVIPActive)
    }

    func grantJade(_ amount: Int) async throws -> FortuneEntitlementSnapshot {
        try await prepareIfNeeded()
        let context = ModelContext(container)
        let entity = try entitlementEntity(in: context)
        entity.jadeBalance += max(amount, 0)
        try context.save()
        return FortuneEntitlementSnapshot(jadeBalance: entity.jadeBalance, isVIPActive: entity.isVIPActive)
    }

    func setVIPActive(_ isActive: Bool) async throws -> FortuneEntitlementSnapshot {
        try await prepareIfNeeded()
        let context = ModelContext(container)
        let entity = try entitlementEntity(in: context)
        entity.isVIPActive = isActive
        try context.save()
        return FortuneEntitlementSnapshot(jadeBalance: entity.jadeBalance, isVIPActive: entity.isVIPActive)
    }

    func loadFavorites() async throws -> [NamingCandidateContent] {
        try await prepareIfNeeded()
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<LocalNamingFavoriteEntity>()
        let favorites = try context.fetch(descriptor).map(favoriteSnapshot(from:))
        return sortFavorites(favorites)
    }

    func toggleFavorite(_ candidate: NamingCandidateContent) async throws -> [NamingCandidateContent] {
        try await prepareIfNeeded()
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<LocalNamingFavoriteEntity>()
        let favorites = try context.fetch(descriptor)

        if let existing = favorites.first(where: { $0.candidateId == candidate.id }) {
            context.delete(existing)
        } else {
            context.insert(
                LocalNamingFavoriteEntity(
                    candidateId: candidate.id,
                    title: candidate.title,
                    fiveElementSummary: candidate.fiveElementSummary,
                    scoreText: candidate.scoreText
                )
            )
        }

        try context.save()
        return try await loadFavorites()
    }

    func loadDailyKnowledge() async throws -> [DailyGuidanceKnowledge] {
        try await prepareIfNeeded()
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<LocalDailyGuidanceRuleEntity>())
            .sorted(by: { $0.ruleId < $1.ruleId })
            .map { entity in
                DailyGuidanceKnowledge(
                    ruleId: entity.ruleId,
                    primaryElement: entity.primaryElement,
                    favorableLevels: splitCSV(entity.favorableLevelsCSV),
                    heroSubtitle: entity.heroSubtitle,
                    rhythmDescriptor: entity.rhythmDescriptor,
                    recommendations: splitCSV(entity.recommendationsCSV),
                    cautions: splitCSV(entity.cautionsCSV),
                    oracleCategory: entity.oracleCategory,
                    oracleHead: entity.oracleHead,
                    oracleBody: entity.oracleBody,
                    adviceKeyword: entity.adviceKeyword,
                    supportKeywords: splitCSV(entity.supportKeywordsCSV),
                    riskKeywords: splitCSV(entity.riskKeywordsCSV),
                    adviceScenes: splitCSV(entity.adviceScenesCSV)
                )
            }
    }

    func loadBaziKnowledge() async throws -> [BaziInsightKnowledge] {
        try await prepareIfNeeded()
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<LocalBaziInsightRuleEntity>())
            .sorted(by: { $0.insightId < $1.insightId })
            .map {
                BaziInsightKnowledge(
                    insightId: $0.insightId,
                    dominantElement: $0.dominantElement,
                    supportElement: $0.supportElement,
                    strengthLabels: splitCSV($0.strengthLabelsCSV),
                    focusTags: splitCSV($0.focusTagsCSV),
                    interpretationTemplate: $0.interpretationTemplate,
                    advisoryFocus: $0.advisoryFocus
                )
            }
    }

    func loadNamingKnowledge() async throws -> NamingLexiconKnowledge {
        try await prepareIfNeeded()
        let context = ModelContext(container)
        let surnameEntries = try context.fetch(FetchDescriptor<LocalNamingSurnameLexiconEntity>())
            .sorted(by: {
                if $0.weight != $1.weight {
                    return $0.weight > $1.weight
                }
                return $0.entryId < $1.entryId
            })
            .map {
                NamingSurnameKnowledge(
                    value: $0.value,
                    weight: $0.weight,
                    styleTags: splitCSV($0.styleTagsCSV)
                )
            }
        let givenNames = try context.fetch(FetchDescriptor<LocalNamingGivenNameLexiconEntity>())
            .sorted(by: {
                if $0.weight != $1.weight {
                    return $0.weight > $1.weight
                }
                return $0.entryId < $1.entryId
            })
            .map {
                NamingGivenNameKnowledge(
                    entryId: $0.entryId,
                    leading: $0.leading,
                    trailing: $0.trailing,
                    element: $0.element,
                    supportElement: $0.supportElement,
                    mood: $0.mood,
                    genderAffinity: $0.genderAffinity,
                    semanticTags: splitCSV($0.semanticTagsCSV),
                    styleLabel: $0.styleLabel,
                    commonnessRank: $0.commonnessRank,
                    writingComplexity: $0.writingComplexity,
                    weight: $0.weight,
                    notes: $0.notes
                )
            }

        return NamingLexiconKnowledge(surnameEntries: surnameEntries, givenNames: givenNames)
    }

    func loadCompatibilityKnowledge() async throws -> [CompatibilityTemplateKnowledge] {
        try await prepareIfNeeded()
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<LocalCompatibilityGuidanceTemplateEntity>())
            .sorted(by: { $0.minimumScore < $1.minimumScore })
            .map {
                CompatibilityTemplateKnowledge(
                    templateId: $0.templateId,
                    minimumScore: $0.minimumScore,
                    maximumScore: $0.maximumScore,
                    scoreBandKey: $0.scoreBandKey,
                    bandLabel: $0.bandLabel,
                    relationTags: splitCSV($0.relationTagsCSV),
                    focusKeywords: splitCSV($0.focusKeywordsCSV),
                    sharedTone: $0.sharedTone,
                    nearRhythmLine: $0.nearRhythmLine,
                    farRhythmLine: $0.farRhythmLine,
                    highScoreCaution: $0.highScoreCaution,
                    baseCaution: $0.baseCaution
                )
            }
    }

    private func syncKnowledgeCatalogIfNeeded(in context: ModelContext) throws {
        let catalog = try LocalKnowledgeBaseLoader.loadCatalog()
        let marker = try fetchFirst(LocalKnowledgeCatalogVersionEntity.self, in: context)
        guard marker?.schemaVersion != catalog.schemaVersion else { return }
        try clearKnowledgeTables(in: context)

        for entry in catalog.dailyGuidance {
            context.insert(
                LocalDailyGuidanceRuleEntity(
                    ruleId: entry.ruleId,
                    primaryElement: entry.primaryElement,
                    favorableLevelsCSV: joinCSV(entry.favorableLevels),
                    heroSubtitle: entry.heroSubtitle,
                    rhythmDescriptor: entry.rhythmDescriptor,
                    recommendationsCSV: joinCSV(entry.recommendations),
                    cautionsCSV: joinCSV(entry.cautions),
                    oracleCategory: entry.oracleCategory,
                    oracleHead: entry.oracleHead,
                    oracleBody: entry.oracleBody,
                    adviceKeyword: entry.adviceKeyword,
                    supportKeywordsCSV: joinCSV(entry.supportKeywords),
                    riskKeywordsCSV: joinCSV(entry.riskKeywords),
                    adviceScenesCSV: joinCSV(entry.adviceScenes)
                )
            )
        }
        for entry in catalog.baziInsights {
            context.insert(
                LocalBaziInsightRuleEntity(
                    insightId: entry.insightId,
                    dominantElement: entry.dominantElement,
                    supportElement: entry.supportElement,
                    strengthLabelsCSV: joinCSV(entry.strengthLabels),
                    focusTagsCSV: joinCSV(entry.focusTags),
                    interpretationTemplate: entry.interpretationTemplate,
                    advisoryFocus: entry.advisoryFocus
                )
            )
        }
        for (index, entry) in catalog.namingLexicon.surnameEntries.enumerated() {
            context.insert(
                LocalNamingSurnameLexiconEntity(
                    entryId: "surname-\(index)-\(entry.value)",
                    value: entry.value,
                    weight: entry.weight,
                    styleTagsCSV: joinCSV(entry.styleTags)
                )
            )
        }
        for entry in catalog.namingLexicon.givenNames {
            context.insert(
                LocalNamingGivenNameLexiconEntity(
                    entryId: entry.entryId,
                    leading: entry.leading,
                    trailing: entry.trailing,
                    element: entry.element,
                    supportElement: entry.supportElement,
                    mood: entry.mood,
                    genderAffinity: entry.genderAffinity,
                    semanticTagsCSV: joinCSV(entry.semanticTags),
                    styleLabel: entry.styleLabel,
                    commonnessRank: entry.commonnessRank,
                    writingComplexity: entry.writingComplexity,
                    weight: entry.weight,
                    notes: entry.notes
                )
            )
        }
        for entry in catalog.compatibilityTemplates {
            context.insert(
                LocalCompatibilityGuidanceTemplateEntity(
                    templateId: entry.templateId,
                    minimumScore: entry.minimumScore,
                    maximumScore: entry.maximumScore,
                    scoreBandKey: entry.scoreBandKey,
                    bandLabel: entry.bandLabel,
                    relationTagsCSV: joinCSV(entry.relationTags),
                    focusKeywordsCSV: joinCSV(entry.focusKeywords),
                    sharedTone: entry.sharedTone,
                    nearRhythmLine: entry.nearRhythmLine,
                    farRhythmLine: entry.farRhythmLine,
                    highScoreCaution: entry.highScoreCaution,
                    baseCaution: entry.baseCaution
                )
            )
        }

        if let marker {
            marker.schemaVersion = catalog.schemaVersion
            marker.importedAt = .now
        } else {
            context.insert(
                LocalKnowledgeCatalogVersionEntity(
                    catalogKey: Constants.catalogKey,
                    schemaVersion: catalog.schemaVersion
                )
            )
        }
    }

    private func migrateLegacyProfileIfNeeded(in context: ModelContext) throws {
        guard try fetchFirst(LocalProfileEntity.self, in: context) == nil,
              let data = legacyDefaults.data(forKey: Constants.profileStorageKey) else {
            return
        }

        let profile = try JSONDecoder().decode(ProfileSnapshot.self, from: data)
        context.insert(
            LocalProfileEntity(
                profileId: profile.profileId,
                birthDate: profile.birthDate,
                birthHourLabel: profile.birthHourLabel,
                gender: profile.gender,
                calendarType: profile.calendarType,
                lastUpdatedAt: profile.lastUpdatedAt
            )
        )
        context.insert(LocalProfileCalendarMetaEntity(profileId: profile.profileId, isLeapMonth: profile.isLeapMonth))
        legacyDefaults.removeObject(forKey: Constants.profileStorageKey)
    }

    private func migrateLegacyEntitlementIfNeeded(in context: ModelContext) throws {
        guard try fetchFirst(LocalEntitlementEntity.self, in: context) == nil else {
            return
        }

        let hasLegacyBalance = legacyDefaults.object(forKey: Constants.jadeBalanceKey) != nil
        let hasLegacyVIP = legacyDefaults.object(forKey: Constants.vipActiveKey) != nil
        guard hasLegacyBalance || hasLegacyVIP else { return }

        let balance = hasLegacyBalance ? legacyDefaults.integer(forKey: Constants.jadeBalanceKey) : Constants.defaultJadeBalance
        let isVIPActive = legacyDefaults.bool(forKey: Constants.vipActiveKey)
        context.insert(LocalEntitlementEntity(walletId: Constants.walletId, jadeBalance: balance, isVIPActive: isVIPActive))
        legacyDefaults.removeObject(forKey: Constants.jadeBalanceKey)
        legacyDefaults.removeObject(forKey: Constants.vipActiveKey)
    }

    private func migrateLegacyFavoritesIfNeeded(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<LocalNamingFavoriteEntity>()
        guard try context.fetch(descriptor).isEmpty,
              let data = legacyDefaults.data(forKey: Constants.favoritesStorageKey) else {
            return
        }

        let favorites = try JSONDecoder().decode([NamingCandidateContent].self, from: data)
        for favorite in favorites {
            context.insert(
                LocalNamingFavoriteEntity(
                    candidateId: favorite.id,
                    title: favorite.title,
                    fiveElementSummary: favorite.fiveElementSummary,
                    scoreText: favorite.scoreText
                )
            )
        }
        legacyDefaults.removeObject(forKey: Constants.favoritesStorageKey)
    }

    private func ensureEntitlementExists(in context: ModelContext) throws {
        guard try fetchFirst(LocalEntitlementEntity.self, in: context) == nil else { return }
        context.insert(
            LocalEntitlementEntity(
                walletId: Constants.walletId,
                jadeBalance: Constants.defaultJadeBalance,
                isVIPActive: false
            )
        )
    }

    private func entitlementEntity(in context: ModelContext) throws -> LocalEntitlementEntity {
        if let entity = try fetchFirst(LocalEntitlementEntity.self, in: context) {
            return entity
        }
        let fallback = LocalEntitlementEntity(
            walletId: Constants.walletId,
            jadeBalance: Constants.defaultJadeBalance,
            isVIPActive: false
        )
        context.insert(fallback)
        try context.save()
        return fallback
    }

    private func clearKnowledgeTables(in context: ModelContext) throws {
        try context.fetch(FetchDescriptor<LocalDailyGuidanceEntity>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<LocalBaziInsightEntity>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<LocalNamingLexiconEntity>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<LocalCompatibilityTemplateEntity>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<LocalKnowledgeSeedEntity>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<LocalDailyGuidanceRuleEntity>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<LocalBaziInsightRuleEntity>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<LocalNamingSurnameLexiconEntity>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<LocalNamingGivenNameLexiconEntity>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<LocalCompatibilityGuidanceTemplateEntity>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<LocalKnowledgeCatalogVersionEntity>()).forEach(context.delete)
    }

    private func fetchFirst<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws -> T? {
        var descriptor = FetchDescriptor<T>()
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func profileCalendarMetaEntity(
        for profileId: String,
        in context: ModelContext
    ) throws -> LocalProfileCalendarMetaEntity? {
        let descriptor = FetchDescriptor<LocalProfileCalendarMetaEntity>(
            predicate: #Predicate { $0.profileId == profileId }
        )
        return try context.fetch(descriptor).first
    }

    private func splitCSV(_ text: String) -> [String] {
        text
            .split(separator: "|")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }

    private func joinCSV(_ values: [String]) -> String {
        values.joined(separator: "|")
    }

    private func profileSnapshot(from entity: LocalProfileEntity, in context: ModelContext) -> ProfileSnapshot {
        let isLeapMonth = (try? profileCalendarMetaEntity(for: entity.profileId, in: context)?.isLeapMonth) ?? false
        return ProfileSnapshot(
            profileId: entity.profileId,
            birthDate: entity.birthDate,
            birthHourLabel: entity.birthHourLabel,
            gender: entity.gender,
            calendarType: entity.calendarType,
            isLeapMonth: isLeapMonth,
            lastUpdatedAt: entity.lastUpdatedAt
        )
    }

    private func favoriteSnapshot(from entity: LocalNamingFavoriteEntity) -> NamingCandidateContent {
        NamingCandidateContent(
            id: entity.candidateId,
            title: entity.title,
            fiveElementSummary: entity.fiveElementSummary,
            scoreText: entity.scoreText,
            isFavorite: true
        )
    }

    private func sortFavorites(_ favorites: [NamingCandidateContent]) -> [NamingCandidateContent] {
        favorites.sorted { lhs, rhs in
            let lhsScore = favoriteScore(from: lhs.scoreText)
            let rhsScore = favoriteScore(from: rhs.scoreText)

            if lhsScore != rhsScore {
                return lhsScore > rhsScore
            }

            return lhs.title < rhs.title
        }
    }

    private func favoriteScore(from text: String) -> Int {
        Int(text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
    }
}

private enum LocalKnowledgeBaseLoader {
    static func loadCatalog() throws -> FortuneKnowledgeCatalog {
        guard let url = resourceURL() else {
            throw LocalKnowledgeBaseError.missingResource
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(FortuneKnowledgeCatalog.self, from: data)
        } catch is DecodingError {
            throw LocalKnowledgeBaseError.decodeFailed
        } catch {
            throw error
        }
    }

    private static func resourceURL() -> URL? {
        let fileName = "FortuneKnowledgeBase-v1"
        let fileExtension = "json"

        for bundle in Bundle.allBundles + Bundle.allFrameworks {
            if let url = bundle.url(forResource: fileName, withExtension: fileExtension) {
                return url
            }
            if let url = bundle.url(
                forResource: fileName,
                withExtension: fileExtension,
                subdirectory: "KnowledgeBase"
            ) {
                return url
            }
            if let resourceURL = bundle.resourceURL {
                let nestedURL = resourceURL
                    .appendingPathComponent("KnowledgeBase", isDirectory: true)
                    .appendingPathComponent("\(fileName).\(fileExtension)")
                if FileManager.default.fileExists(atPath: nestedURL.path) {
                    return nestedURL
                }
            }
        }

        let workingDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let candidate = workingDirectory
            .appendingPathComponent("FortuneTelling", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("KnowledgeBase", isDirectory: true)
            .appendingPathComponent("\(fileName).\(fileExtension)")
        return FileManager.default.fileExists(atPath: candidate.path) ? candidate : nil
    }
}

actor SwiftDataProfileStore: ProfileStoring {
    private let repository: any FortuneLocalRepositorying

    init(repository: any FortuneLocalRepositorying = SwiftDataFortuneRepository.shared) {
        self.repository = repository
    }

    func loadProfile() async throws -> ProfileSnapshot? {
        try await repository.loadProfile()
    }

    func saveProfile(_ profile: ProfileSnapshot) async throws {
        try await repository.saveProfile(profile)
    }
}

actor SwiftDataNamingFavoritesStore: NamingFavoritesStoring {
    private let repository: any FortuneLocalRepositorying

    init(repository: any FortuneLocalRepositorying = SwiftDataFortuneRepository.shared) {
        self.repository = repository
    }

    func loadFavorites() async -> [NamingCandidateContent] {
        (try? await repository.loadFavorites()) ?? []
    }

    func toggleFavorite(_ candidate: NamingCandidateContent) async -> [NamingCandidateContent] {
        (try? await repository.toggleFavorite(candidate)) ?? []
    }
}
