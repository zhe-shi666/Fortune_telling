import SwiftUI

struct NamingRecommendationPayload: Equatable, Sendable {
    var candidates: [NamingCandidateContent]
}

enum NamingRecommendationRenderAdapter {
    static func makeContent(from candidate: FortuneNamingCandidate) -> NamingCandidateContent {
        let highlightLabels = candidate.scoreBreakdown
            .filter { $0.score > 0 && $0.key != "score-calibration" }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.label < rhs.label
                }
                return lhs.score > rhs.score
            }
            .prefix(2)
            .map(\.label)
        let breakdownSummary = highlightLabels.isEmpty
            ? candidate.favorableReason
            : "五行与气质：\(highlightLabels.joined(separator: "、"))。\(candidate.favorableReason)"

        return NamingCandidateContent(
            id: "\(candidate.title)-\(candidate.totalScore)",
            title: candidate.title,
            fiveElementSummary: breakdownSummary,
            scoreText: "得分 \(candidate.totalScore)",
            isFavorite: false
        )
    }
}

enum NamingWorkshopServiceError: LocalizedError, Equatable, Sendable {
    case invalidBirthDate
    case invalidBirthHour
    case invalidGender
    case invalidSurname
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidBirthDate:
            "请先选择有效的出生日期，再生成雅名。"
        case .invalidBirthHour:
            "请先选择出生时辰，再生成雅名。"
        case .invalidGender:
            "请先选择性别，再生成雅名。"
        case .invalidSurname:
            "姓氏仅支持 1 到 2 个中文字符。"
        case .serviceUnavailable:
            "取名服务暂时不可用，请稍后重试。"
        }
    }
}

protocol NamingRecommendationServicing: Sendable {
    func recommendNames(for birthDate: String, birthHourLabel: String, surname: String?, gender: String) async throws -> NamingRecommendationPayload
}

struct LocalNamingRecommendationService: NamingRecommendationServicing {
    private let repository: any FortuneLocalRepositorying

    init(repository: any FortuneLocalRepositorying = SwiftDataFortuneRepository.shared) {
        self.repository = repository
    }

    func recommendNames(for birthDate: String, birthHourLabel: String, surname: String?, gender: String) async throws -> NamingRecommendationPayload {
        guard FortuneValidation.isValidDate(birthDate) else {
            throw NamingWorkshopServiceError.invalidBirthDate
        }
        guard FortuneFieldCatalog.hourOptions.contains(birthHourLabel) else {
            throw NamingWorkshopServiceError.invalidBirthHour
        }
        guard FortuneFieldCatalog.genders.contains(gender) else {
            throw NamingWorkshopServiceError.invalidGender
        }
        guard NamingWorkshopInputSupport.isValidSurname(surname) else {
            throw NamingWorkshopServiceError.invalidSurname
        }

        let lexicon = try await repository.loadNamingKnowledge()
        guard !lexicon.surnames.isEmpty, !lexicon.givenNames.isEmpty else {
            throw NamingWorkshopServiceError.serviceUnavailable
        }

        do {
            let input = FortuneBirthInput(
                birthDate: birthDate,
                birthHourLabel: birthHourLabel,
                gender: gender,
                calendarType: "公历"
            )
            let candidates = try FortuneAlgorithmEngine.recommendNames(
                for: input,
                surname: surname,
                lexicon: lexicon,
                limit: 8
            )

            return NamingRecommendationPayload(
                candidates: candidates.map(NamingRecommendationRenderAdapter.makeContent)
            )
        } catch let error as FortuneAlgorithmError {
            switch error {
            case .invalidInput:
                throw NamingWorkshopServiceError.invalidBirthDate
            case .unsupportedCalendar:
                throw NamingWorkshopServiceError.serviceUnavailable
            }
        } catch {
            throw NamingWorkshopServiceError.serviceUnavailable
        }
    }
}

struct MockNamingRecommendationService: NamingRecommendationServicing {
    enum Behavior: Sendable {
        case success
        case failure(NamingWorkshopServiceError)
    }

    var behavior: Behavior = .success

    func recommendNames(for birthDate: String, birthHourLabel: String, surname: String?, gender: String) async throws -> NamingRecommendationPayload {
        switch behavior {
        case .success:
            guard FortuneValidation.isValidDate(birthDate) else {
                throw NamingWorkshopServiceError.invalidBirthDate
            }
            guard FortuneFieldCatalog.hourOptions.contains(birthHourLabel) else {
                throw NamingWorkshopServiceError.invalidBirthHour
            }
            guard FortuneFieldCatalog.genders.contains(gender) else {
                throw NamingWorkshopServiceError.invalidGender
            }
            guard NamingWorkshopInputSupport.isValidSurname(surname) else {
                throw NamingWorkshopServiceError.invalidSurname
            }

            let resolvedSurname = surname?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? surname!.trimmingCharacters(in: .whitespacesAndNewlines)
                : nil
            let prefix = resolvedSurname ?? "林"
            let candidates: [NamingCandidateContent]
            if gender == "男" {
                candidates = [
                    NamingCandidateContent(id: "\(prefix)-ruo-heng", title: "\(prefix)若衡", fiveElementSummary: "五行：木土", scoreText: "得分 96", isFavorite: false),
                    NamingCandidateContent(id: "\(prefix)-wen-li", title: "\(prefix)闻礼", fiveElementSummary: "五行：金火", scoreText: "得分 94", isFavorite: false),
                    NamingCandidateContent(id: "\(prefix)-yan-qiu", title: "\(prefix)砚秋", fiveElementSummary: "五行：金水", scoreText: "得分 92", isFavorite: false),
                    NamingCandidateContent(id: "\(prefix)-ying-chuan", title: "\(prefix)映川", fiveElementSummary: "五行：火水", scoreText: "得分 90", isFavorite: false)
                ]
            } else {
                candidates = [
                    NamingCandidateContent(id: "\(prefix)-qing-yan", title: "\(prefix)清妍", fiveElementSummary: "五行：水金", scoreText: "得分 96", isFavorite: false),
                    NamingCandidateContent(id: "\(prefix)-xing-lan", title: "\(prefix)星澜", fiveElementSummary: "五行：水木", scoreText: "得分 94", isFavorite: false),
                    NamingCandidateContent(id: "\(prefix)-zhi-xia", title: "\(prefix)知夏", fiveElementSummary: "五行：火土", scoreText: "得分 92", isFavorite: false),
                    NamingCandidateContent(id: "\(prefix)-zhao-ning", title: "\(prefix)昭宁", fiveElementSummary: "五行：火土", scoreText: "得分 90", isFavorite: false)
                ]
            }
            return NamingRecommendationPayload(
                candidates: candidates
            )
        case .failure(let error):
            throw error
        }
    }
}

protocol NamingFavoritesStoring: Sendable {
    func loadFavorites() async -> [NamingCandidateContent]
    func toggleFavorite(_ candidate: NamingCandidateContent) async -> [NamingCandidateContent]
}

actor InMemoryNamingFavoritesStore: NamingFavoritesStoring {
    private var favorites: [String: NamingCandidateContent] = [:]

    func loadFavorites() async -> [NamingCandidateContent] {
        favorites.values.sorted(by: namingFavoritesSort)
    }

    func toggleFavorite(_ candidate: NamingCandidateContent) async -> [NamingCandidateContent] {
        if favorites[candidate.id] != nil {
            favorites[candidate.id] = nil
        } else {
            var favorited = candidate
            favorited.isFavorite = true
            favorites[candidate.id] = favorited
        }
        return await loadFavorites()
    }
}

actor UserDefaultsNamingFavoritesStore: NamingFavoritesStoring {
    private let suiteName: String?
    private let storageKey: String

    init(
        suiteName: String? = nil,
        storageKey: String = "fortune.naming.favorites.v1"
    ) {
        self.suiteName = suiteName
        self.storageKey = storageKey
    }

    func loadFavorites() async -> [NamingCandidateContent] {
        guard let data = defaults().data(forKey: storageKey),
              let favorites = try? JSONDecoder().decode([NamingCandidateContent].self, from: data) else {
            return []
        }

        return favorites.sorted(by: namingFavoritesSort)
    }

    func toggleFavorite(_ candidate: NamingCandidateContent) async -> [NamingCandidateContent] {
        var favorites = await loadFavorites()

        if let index = favorites.firstIndex(where: { $0.id == candidate.id }) {
            favorites.remove(at: index)
        } else {
            var favorited = candidate
            favorited.isFavorite = true
            favorites.append(favorited)
        }

        if let data = try? JSONEncoder().encode(favorites) {
            defaults().set(data, forKey: storageKey)
        }

        return favorites.sorted(by: namingFavoritesSort)
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

private func namingFavoritesSort(_ lhs: NamingCandidateContent, _ rhs: NamingCandidateContent) -> Bool {
    let lhsScore = Int(lhs.scoreText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
    let rhsScore = Int(rhs.scoreText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0

    if lhsScore != rhsScore {
        return lhsScore > rhsScore
    }

    return lhs.title < rhs.title
}

@MainActor
protocol NamingWorkshopRouting: AnyObject {
    func openTab(_ tab: TodayPrimaryTab)
}

enum NamingWorkshopMockFactory {
    static func empty() -> NamingWorkshopState {
        NamingWorkshopState(
            scenario: .empty,
            activeTab: .naming,
            title: "取名 · 雅名",
            subtitle: "先填写姓氏、性别与生辰信息，再为你呈现古韵雅名参考。",
            surnameLabel: "姓氏",
            surname: "",
            surnamePlaceholder: "例如 林（选填）",
            genderLabel: "性别",
            gender: "",
            genderPlaceholder: "请选择性别",
            birthDateLabel: "出生日期",
            birthDate: "",
            birthDatePlaceholder: "例如 2020-08-16",
            birthHourLabel: "",
            birthHourPlaceholder: "请选择出生时辰",
            requiredBadge: "必填",
            generateButtonTitle: "点击生成 2 个雅名",
            clearButtonTitle: "清空推荐列表",
            favoritesButtonTitle: "收藏清单",
            recommendationsTitle: "名字推荐",
            candidates: [],
            favorites: [],
            favoritesContent: NamingFavoritesContent(
                title: "收藏清单",
                subtitle: "你收藏的雅名会保存在这里，可继续比较寓意与五行。",
                emptyTitle: "还没有收藏名字",
                emptyBody: "先在推荐列表点亮心形按钮，再回来集中比较。"
            ),
            isFavoritesPresented: false,
            inlineMessage: "姓氏可选填；填写性别、出生日期与出生时辰后，点击按钮即可开始查看雅名娱乐参考。",
            toastMessage: nil
        )
    }

    static func loading(from state: NamingWorkshopState) -> NamingWorkshopState {
        var next = state
        next.scenario = .loading
        next.inlineMessage = nil
        next.toastMessage = nil
        return next
    }

    static func ideal(
        surname: String,
        gender: String,
        birthDate: String,
        birthHourLabel: String,
        candidates: [NamingCandidateContent],
        favorites: [NamingCandidateContent]
    ) -> NamingWorkshopState {
        var state = empty()
        state.scenario = .ideal
        state.surname = surname
        state.gender = gender
        state.birthDate = birthDate
        state.birthHourLabel = birthHourLabel
        state.candidates = candidates
        state.favorites = favorites
        state.inlineMessage = nil
        state.toastMessage = nil
        return state
    }

    static func error(from state: NamingWorkshopState, message: String) -> NamingWorkshopState {
        var next = state
        next.scenario = .error
        next.inlineMessage = message
        next.toastMessage = nil
        return next
    }
}

@MainActor
final class NamingWorkshopViewModel: ObservableObject {
    @Published var state: NamingWorkshopState
    weak var router: (any NamingWorkshopRouting)?

    private let service: any NamingRecommendationServicing
    private let profileStore: any ProfileStoring
    private let favoritesStore: any NamingFavoritesStoring
    private let entitlementService: any FortuneEntitlementServicing
    private let recommendationBatchSize = 2
    private var hasLoaded = false
    private var recommendationPool: [NamingCandidateContent] = []
    private var generatedInputKey: String?

    init(
        service: any NamingRecommendationServicing,
        profileStore: any ProfileStoring,
        favoritesStore: any NamingFavoritesStoring,
        entitlementService: any FortuneEntitlementServicing = InMemoryFortuneEntitlementService(),
        initialState: NamingWorkshopState = NamingWorkshopMockFactory.empty(),
        router: (any NamingWorkshopRouting)? = nil
    ) {
        self.service = service
        self.profileStore = profileStore
        self.favoritesStore = favoritesStore
        self.entitlementService = entitlementService
        self.state = initialState
        self.router = router
    }

    func refreshIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await refresh()
    }

    func refresh() async {
        let favorites = await favoritesStore.loadFavorites()
        recommendationPool = []
        generatedInputKey = nil

        do {
            if let profile = try await profileStore.loadProfile(), FortuneValidation.isValidDate(profile.birthDate) {
                var next = NamingWorkshopMockFactory.empty()
                next.birthDate = profile.birthDate
                next.birthHourLabel = profile.birthHourLabel
                next.gender = profile.gender
                next.favorites = favorites
                next.inlineMessage = "姓氏可选填；填写的性别会参与名字排序。\(FortuneProductCopy.usageRule(for: .naming))"
                state = next
            } else {
                var next = NamingWorkshopMockFactory.empty()
                next.favorites = favorites
                next.inlineMessage = FortuneProductCopy.usageRule(for: .naming)
                state = next
            }
        } catch {
            state = NamingWorkshopMockFactory.error(from: state, message: error.localizedDescription)
        }
    }

    func send(_ action: NamingWorkshopAction) {
        switch action {
        case .updateSurname(let value):
            let normalized = NamingWorkshopInputSupport.normalizedSurnameInput(value)
            let previous = state.surname.trimmingCharacters(in: .whitespacesAndNewlines)
            state.surname = normalized
            if normalized != previous {
                clearRecommendations(userTriggered: false)
            }
            if state.scenario != .loading {
                state.scenario = .empty
            }
            state.inlineMessage = NamingWorkshopInputSupport.validationMessage(for: normalized)
            state.toastMessage = nil
        case .updateGender(let value):
            let previous = state.gender
            state.gender = value
            if value != previous {
                clearRecommendations(userTriggered: false)
            }
            if state.scenario != .loading {
                state.scenario = .empty
            }
            state.inlineMessage = FortuneFieldCatalog.genders.contains(value) ? nil : NamingWorkshopServiceError.invalidGender.localizedDescription
            state.toastMessage = nil
        case .updateBirthDate(let value):
            let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
            let previous = state.birthDate.trimmingCharacters(in: .whitespacesAndNewlines)
            state.birthDate = value
            if normalized != previous {
                clearRecommendations(userTriggered: false)
            }
            if state.scenario != .loading {
                state.scenario = .empty
            }
            state.inlineMessage = nil
            state.toastMessage = nil
        case .updateBirthHour(let value):
            let previous = state.birthHourLabel
            state.birthHourLabel = value
            if value != previous {
                clearRecommendations(userTriggered: false)
            }
            if state.scenario != .loading {
                state.scenario = .empty
            }
            state.inlineMessage = nil
            state.toastMessage = nil
        case .generate:
            Task {
                let favorites = await favoritesStore.loadFavorites()
                await consumeAndGenerate(
                    for: state.birthDate,
                    birthHourLabel: state.birthHourLabel,
                    surname: state.surname,
                    gender: state.gender,
                    existingFavorites: favorites
                )
            }
        case .clearRecommendations:
            clearRecommendations(userTriggered: true)
        case .toggleFavorite(let candidateId):
            Task { await toggleFavorite(candidateId) }
        case .presentFavorites(let isPresented):
            state.isFavoritesPresented = isPresented
        case .openTab(let tab):
            guard tab != .naming else { return }
            router?.openTab(tab)
        }
    }

    private func consumeAndGenerate(
        for birthDate: String,
        birthHourLabel: String,
        surname: String,
        gender: String,
        existingFavorites: [NamingCandidateContent]
    ) async {
        let trimmedBirthDate = birthDate.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBirthHour = birthHourLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSurname = NamingWorkshopInputSupport.normalizedSurnameInput(surname)
        let trimmedGender = gender.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedSurname = trimmedSurname.isEmpty ? nil : trimmedSurname
        let requestKey = "\(trimmedBirthDate)|\(trimmedBirthHour)|\(trimmedGender)|\(resolvedSurname ?? "")"

        guard FortuneValidation.isValidDate(trimmedBirthDate) else {
            var next = NamingWorkshopMockFactory.empty()
            next.surname = surname
            next.gender = gender
            next.birthDate = birthDate
            next.birthHourLabel = birthHourLabel
            next.favorites = existingFavorites
            state = next
            return
        }
        guard FortuneFieldCatalog.hourOptions.contains(trimmedBirthHour) else {
            var next = NamingWorkshopMockFactory.empty()
            next.surname = surname
            next.gender = gender
            next.birthDate = birthDate
            next.birthHourLabel = birthHourLabel
            next.favorites = existingFavorites
            next.inlineMessage = NamingWorkshopServiceError.invalidBirthHour.localizedDescription
            state = next
            return
        }
        guard FortuneFieldCatalog.genders.contains(trimmedGender) else {
            var next = NamingWorkshopMockFactory.empty()
            next.surname = surname
            next.gender = gender
            next.birthDate = birthDate
            next.birthHourLabel = birthHourLabel
            next.favorites = existingFavorites
            next.inlineMessage = NamingWorkshopServiceError.invalidGender.localizedDescription
            state = next
            return
        }
        guard NamingWorkshopInputSupport.isValidSurname(trimmedSurname) else {
            var next = NamingWorkshopMockFactory.empty()
            next.surname = trimmedSurname
            next.gender = gender
            next.birthDate = birthDate
            next.birthHourLabel = birthHourLabel
            next.favorites = existingFavorites
            next.inlineMessage = NamingWorkshopServiceError.invalidSurname.localizedDescription
            state = next
            return
        }

        do {
            _ = try await entitlementService.consumeIfNeeded(for: .naming)
        } catch {
            state.inlineMessage = error.localizedDescription
            return
        }

        if generatedInputKey == requestKey, !recommendationPool.isEmpty {
            revealNextBatch(
                for: trimmedBirthDate,
                birthHourLabel: trimmedBirthHour,
                surname: surname,
                gender: trimmedGender,
                favorites: existingFavorites
            )
            return
        }

        let previous = state
        state = NamingWorkshopMockFactory.loading(from: previous)

        do {
            let payload = try await service.recommendNames(
                for: trimmedBirthDate,
                birthHourLabel: trimmedBirthHour,
                surname: resolvedSurname,
                gender: trimmedGender
            )
            recommendationPool = mergeFavorites(payload.candidates, favorites: existingFavorites)
            generatedInputKey = requestKey
            revealNextBatch(
                for: trimmedBirthDate,
                birthHourLabel: trimmedBirthHour,
                surname: surname,
                gender: trimmedGender,
                favorites: existingFavorites
            )
        } catch {
            state = NamingWorkshopMockFactory.error(from: previous, message: error.localizedDescription)
        }
    }

    private func toggleFavorite(_ candidateId: String) async {
        guard let candidate = state.candidates.first(where: { $0.id == candidateId }) else { return }
        let favorites = await favoritesStore.toggleFavorite(candidate)
        let favoriteIds = Set(favorites.map(\.id))

        state.candidates = state.candidates.map { item in
            var next = item
            next.isFavorite = favoriteIds.contains(item.id)
            return next
        }
        state.favorites = favorites
        state.toastMessage = favoriteIds.contains(candidate.id) ? "已加入收藏清单" : "已从收藏清单移除"
        scheduleToastDismiss()
    }

    private func clearRecommendations(userTriggered: Bool) {
        recommendationPool = []
        generatedInputKey = nil
        state.candidates = []
        state.scenario = .empty
        state.toastMessage = nil
        if userTriggered {
            state.inlineMessage = "已清空当前推荐，可重新生成新的雅名参考。"
        }
    }

    private func revealNextBatch(
        for birthDate: String,
        birthHourLabel: String,
        surname: String,
        gender: String,
        favorites: [NamingCandidateContent]
    ) {
        let shownIds = Set(state.candidates.map(\.id))
        let nextBatch = recommendationPool.filter { !shownIds.contains($0.id) }.prefix(recommendationBatchSize)

        if nextBatch.isEmpty {
            if !state.candidates.isEmpty {
                state.inlineMessage = "当前日期的雅名已全部展示，可更换日期重新生成。"
                state.scenario = .ideal
            }
            return
        }

        let combined = Array(nextBatch) + state.candidates
        state = NamingWorkshopMockFactory.ideal(
            surname: surname,
            gender: gender,
            birthDate: birthDate,
            birthHourLabel: birthHourLabel,
            candidates: combined,
            favorites: favorites
        )
    }

    private func mergeFavorites(
        _ candidates: [NamingCandidateContent],
        favorites: [NamingCandidateContent]
    ) -> [NamingCandidateContent] {
        let favoriteIds = Set(favorites.map(\.id))
        return candidates.map { candidate in
            var next = candidate
            next.isFavorite = favoriteIds.contains(candidate.id)
            return next
        }
    }

    private func scheduleToastDismiss() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            self?.state.toastMessage = nil
        }
    }
}

struct NamingWorkshopView: View {
    @ObservedObject var viewModel: NamingWorkshopViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0C0A07), Color(hex: 0x1E1610)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    header
                    inputCard

                    if let inlineMessage = regularInlineMessage {
                        FortuneInlineNotice(
                            message: inlineMessage,
                            tone: viewModel.state.scenario == .error ? .error : .info
                        )
                    }

                    recommendationsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                FortuneMainTabBar(selectedTab: .naming) { tab in
                    viewModel.send(.openTab(tab))
                }
                .padding(.horizontal, 21)
                .padding(.vertical, 10)
                .background(Color(hex: 0x1A140D))
            }
        }
        .overlay {
            if viewModel.state.isFavoritesPresented {
                favoritesOverlay
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage = viewModel.state.toastMessage {
                FortuneToastBubble(message: toastMessage)
                    .padding(.bottom, 94)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.refreshIfNeeded()
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.state.toastMessage)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.state.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color(hex: 0xF6EBD6))
                        .lineLimit(2)
                        .layoutPriority(1)
                        .minimumScaleFactor(0.9)

                    FortuneReferenceBadge()
                }

                Spacer(minLength: 0)

                favoritesButton
            }

            Text(viewModel.state.subtitle)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: 0xBCA98A))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var favoritesButton: some View {
        Button {
            viewModel.send(.presentFavorites(true))
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "heart")
                Text(viewModel.state.favoritesButtonTitle)
                Image(systemName: "chevron.right")
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color(hex: 0xEADFC8))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: 0x2A1F15, opacity: 0.86))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(hex: 0x6E5A3B), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            FortuneFieldHintText(
                text: "姓氏支持 1 到 2 个中文字符；普通用户每次生成消耗 1 灵玉，VIP 不消耗。",
                tone: .dark
            )

            VStack(alignment: .leading, spacing: 6) {
                FortuneFieldHeader(
                    title: viewModel.state.surnameLabel,
                    tone: .dark
                )

                TextField(
                    viewModel.state.surnamePlaceholder,
                    text: Binding(
                        get: { viewModel.state.surname },
                        set: { viewModel.send(.updateSurname($0)) }
                    )
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .fortuneInputChrome(tone: .dark)
            }

            VStack(alignment: .leading, spacing: 6) {
                FortuneFieldHeader(
                    title: viewModel.state.genderLabel,
                    requiredBadge: viewModel.state.requiredBadge,
                    tone: .dark
                )

                Menu {
                    ForEach(FortuneFieldCatalog.genders, id: \.self) { option in
                        Button(option) {
                            viewModel.send(.updateGender(option))
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.state.gender.isEmpty ? viewModel.state.genderPlaceholder : viewModel.state.gender)
                            .lineLimit(1)
                            .foregroundStyle(
                                viewModel.state.gender.isEmpty
                                ? FortuneFieldTone.dark.textColor.opacity(0.72)
                                : FortuneFieldTone.dark.textColor
                            )

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x8C6D45))
                    }
                    .fortuneInputChrome(tone: .dark)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.state.scenario == .loading)
                .opacity(viewModel.state.scenario == .loading ? 0.6 : 1)
            }

            FortuneFieldHeader(
                title: viewModel.state.birthDateLabel,
                requiredBadge: viewModel.state.requiredBadge,
                tone: .dark
            )

            FortuneCompactBirthDateField(
                text: Binding(
                    get: { viewModel.state.birthDate },
                    set: { viewModel.send(.updateBirthDate($0)) }
                ),
                tone: .dark,
                isEnabled: viewModel.state.scenario != .loading
            )

            VStack(alignment: .leading, spacing: 6) {
                FortuneFieldHeader(
                    title: "出生时辰",
                    requiredBadge: viewModel.state.requiredBadge,
                    tone: .dark
                )

                Menu {
                    ForEach(FortuneFieldCatalog.hourOptions, id: \.self) { option in
                        Button(option) {
                            viewModel.send(.updateBirthHour(option))
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.state.birthHourLabel.isEmpty ? viewModel.state.birthHourPlaceholder : viewModel.state.birthHourLabel)
                            .lineLimit(1)
                            .foregroundStyle(
                                viewModel.state.birthHourLabel.isEmpty
                                ? FortuneFieldTone.dark.textColor.opacity(0.72)
                                : FortuneFieldTone.dark.textColor
                            )

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x8C6D45))
                    }
                    .fortuneInputChrome(tone: .dark)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.state.scenario == .loading)
                .opacity(viewModel.state.scenario == .loading ? 0.6 : 1)
            }

            Button {
                viewModel.send(.generate)
            } label: {
                HStack(spacing: 8) {
                    if viewModel.state.scenario == .loading {
                        ProgressView()
                            .tint(FortuneTheme.Palette.textOnDark)
                    }
                    Text(viewModel.state.generateButtonTitle)
                }
            }
            .buttonStyle(FortunePrimaryButtonStyle())
            .disabled(!canGenerate)
            .opacity(canGenerate ? 1 : 0.55)

            Button(viewModel.state.clearButtonTitle) {
                viewModel.send(.clearRecommendations)
            }
            .buttonStyle(FortuneSecondaryButtonStyle())
            .disabled(viewModel.state.candidates.isEmpty)
            .opacity(viewModel.state.candidates.isEmpty ? 0.45 : 1)
        }
        .padding(12)
        .background(Color(hex: 0x18120D))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: 0x5A472F), lineWidth: 1)
        )
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.state.recommendationsTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: 0xD9C4A1))

            if viewModel.state.candidates.isEmpty {
                emptyRecommendationCard
            } else {
                ForEach(viewModel.state.candidates) { candidate in
                    candidateCard(candidate, isInPanel: false)
                        .redacted(reason: viewModel.state.scenario == .loading ? .placeholder : [])
                }

                if let completionMessage {
                    completionNotice(message: completionMessage)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyRecommendationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("等待生成")
                .font(FortuneTheme.Typography.cardTitle)
                .foregroundStyle(Color(hex: 0xF1E2C6))

            Text("可先填入常用姓氏，再选择性别、输入有效的出生日期与出生时辰。点击按钮会先显示 2 个雅名娱乐参考；再次点击会继续追加。")
                .font(FortuneTheme.Typography.body)
                .foregroundStyle(Color(hex: 0xBCA98A))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0x1B140F))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0x6B563A), lineWidth: 1)
        )
    }

    private func candidateCard(_ candidate: NamingCandidateContent, isInPanel: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text(candidate.title)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(.white)

                ViewThatFits(in: .vertical) {
                    HStack(spacing: 8) {
                        candidateSummary(candidate)
                        candidateScore(candidate)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        candidateSummary(candidate)
                        candidateScore(candidate)
                    }
                }
            }

            Spacer()

            Button {
                viewModel.send(.toggleFavorite(candidate.id))
            } label: {
                Image(systemName: candidate.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(candidate.isFavorite ? Color(hex: 0xE2B16E) : Color(hex: 0xB7925C))
                    .frame(width: 34, height: 34)
                    .background(Color(hex: 0x20170F))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(hex: 0x6B563A), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: isInPanel ? [Color(hex: 0x241A12), Color(hex: 0x17110D)] : [Color(hex: 0x2A2017), Color(hex: 0x1B140F)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0x6B563A), lineWidth: 1)
        )
    }

    private func candidateSummary(_ candidate: NamingCandidateContent) -> some View {
        Text(candidate.fiveElementSummary)
            .font(FortuneTheme.Typography.small)
            .foregroundStyle(Color(hex: 0xD3C3A5))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func candidateScore(_ candidate: NamingCandidateContent) -> some View {
        Text(candidate.scoreText)
            .font(FortuneTheme.Typography.small)
            .foregroundStyle(Color(hex: 0xEBD9B2))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: 0x5A452E))
            .clipShape(Capsule())
    }

    private var canGenerate: Bool {
        FortuneFieldCatalog.genders.contains(viewModel.state.gender)
            && FortuneValidation.isValidDate(viewModel.state.birthDate)
            && FortuneFieldCatalog.hourOptions.contains(viewModel.state.birthHourLabel)
            && NamingWorkshopInputSupport.isValidSurname(viewModel.state.surname)
            && viewModel.state.scenario != .loading
    }

    private var regularInlineMessage: String? {
        if completionMessage != nil {
            return nil
        }
        return viewModel.state.inlineMessage
    }

    private var completionMessage: String? {
        let target = "当前日期的雅名已全部展示，可更换日期重新生成。"
        guard viewModel.state.inlineMessage == target, !viewModel.state.candidates.isEmpty else {
            return nil
        }
        return target
    }

    private func completionNotice(message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(Color(hex: 0xE5BE76))

            VStack(alignment: .leading, spacing: 4) {
                Text("当前日期已展示完")
                    .font(FortuneTheme.Typography.label)
                    .foregroundStyle(Color(hex: 0xF1E2C6))

                Text(message)
                    .font(FortuneTheme.Typography.small)
                    .foregroundStyle(Color(hex: 0xC8B18B))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(hex: 0x16110D))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: 0x6B563A), lineWidth: 1)
        )
    }

    private var favoritesOverlay: some View {
        ZStack {
            Color.black.opacity(0.48)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.send(.presentFavorites(false))
                }

            FortunePopupSurface(tone: .dark, maxWidth: 358, maxHeight: 520) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.state.favoritesContent.title)
                                .font(FortuneTheme.Typography.cardTitle)
                                .foregroundStyle(Color(hex: 0xF1E2C6))

                            Text(viewModel.state.favoritesContent.subtitle)
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: 0xBCA98A))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Button("关闭") {
                            viewModel.send(.presentFavorites(false))
                        }
                        .buttonStyle(.plain)
                        .font(FortuneTheme.Typography.small)
                        .foregroundStyle(Color(hex: 0xD9C4A1))
                    }

                    if viewModel.state.favorites.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(viewModel.state.favoritesContent.emptyTitle)
                                .font(FortuneTheme.Typography.label)
                                .foregroundStyle(Color(hex: 0xF1E2C6))

                            Text(viewModel.state.favoritesContent.emptyBody)
                                .font(FortuneTheme.Typography.body)
                                .foregroundStyle(Color(hex: 0xBCA98A))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: 0x17110D))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 10) {
                                ForEach(viewModel.state.favorites) { candidate in
                                    candidateCard(candidate, isInPanel: true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

enum NamingWorkshopInputSupport {
    private static let chineseScalarRange = 0x4E00...0x9FFF

    static func normalizedSurnameInput(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isValidSurname(_ raw: String?) -> Bool {
        guard let raw else { return true }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        let scalars = Array(trimmed.unicodeScalars)
        guard (1...2).contains(scalars.count) else {
            return false
        }
        return scalars.allSatisfy { chineseScalarRange.contains(Int($0.value)) }
    }

    static func validationMessage(for surname: String) -> String? {
        if surname.isEmpty {
            return nil
        }
        if !isValidSurname(surname) {
            return NamingWorkshopServiceError.invalidSurname.localizedDescription
        }
        return nil
    }
}
