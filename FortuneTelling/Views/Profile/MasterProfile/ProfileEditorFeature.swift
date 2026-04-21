import SwiftUI

struct ProfileEditorState: Equatable, Sendable {
    var scenario: MockScenario
    var title: String
    var subtitle: String
    var birthDate: String
    var birthHourLabel: String
    var gender: String
    var calendarType: String
    var isLeapMonth: Bool
    var noteTitle: String
    var noteBody: String
    var saveButtonTitle: String
    var backButtonTitle: String
    var validationMessage: String?
}

enum ProfileEditorAction: Sendable {
    case updateBirthDate(String)
    case updateBirthHour(String)
    case updateGender(String)
    case updateCalendar(String)
    case updateLeapMonth(Bool)
    case save
    case back
}

@MainActor
protocol ProfileEditorRouting: AnyObject {
    func closeProfileEditor(saved: Bool)
}

enum ProfileEditorMockFactory {
    static func ideal(profile: ProfileSnapshot?) -> ProfileEditorState {
        let snapshot = profile ?? .sample
        return ProfileEditorState(
            scenario: .ideal,
            title: "命主档案",
            subtitle: "先完善出生信息，后续所有推演将依此为准。",
            birthDate: snapshot.birthDate,
            birthHourLabel: snapshot.birthHourLabel,
            gender: snapshot.gender,
            calendarType: snapshot.calendarType,
            isLeapMonth: snapshot.isLeapMonth,
            noteTitle: "依赖说明",
            noteBody: "保存后，今日、八字、合婚与取名都会按最新档案刷新，可随时返回首页继续查看。",
            saveButtonTitle: "保存并用于今日推演",
            backButtonTitle: "返回今日",
            validationMessage: nil
        )
    }

    static func empty() -> ProfileEditorState {
        ProfileEditorState(
            scenario: .empty,
            title: "命主档案",
            subtitle: "先完善出生信息，后续所有推演将依此为准。",
            birthDate: "",
            birthHourLabel: FortuneFieldCatalog.hourOptions[10],
            gender: FortuneFieldCatalog.genders[1],
            calendarType: FortuneFieldCatalog.calendars[0],
            isLeapMonth: false,
            noteTitle: "依赖说明",
            noteBody: "保存后，今日、八字、合婚与取名都会按最新档案刷新，可随时返回首页继续查看。",
            saveButtonTitle: "保存并用于今日推演",
            backButtonTitle: "返回今日",
            validationMessage: "请先填写有效的出生日期。"
        )
    }

    static func loading(from state: ProfileEditorState) -> ProfileEditorState {
        var next = state
        next.scenario = .loading
        next.validationMessage = nil
        return next
    }

    static func error(from state: ProfileEditorState, message: String) -> ProfileEditorState {
        var next = state
        next.scenario = .error
        next.validationMessage = message
        return next
    }
}

@MainActor
final class ProfileEditorViewModel: ObservableObject {
    @Published var state: ProfileEditorState
    weak var router: (any ProfileEditorRouting)?

    private let profileStore: any ProfileStoring
    private let nowProvider: @Sendable () -> Date
    private var hasLoaded = false

    init(
        profileStore: any ProfileStoring,
        initialState: ProfileEditorState = ProfileEditorMockFactory.ideal(profile: .sample),
        nowProvider: @escaping @Sendable () -> Date = { Date() },
        router: (any ProfileEditorRouting)? = nil
    ) {
        self.profileStore = profileStore
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
        do {
            let profile = try await profileStore.loadProfile()
            state = ProfileEditorMockFactory.ideal(profile: profile)
        } catch {
            state = ProfileEditorMockFactory.error(from: state, message: error.localizedDescription)
        }
    }

    func send(_ action: ProfileEditorAction) {
        switch action {
        case .updateBirthDate(let value):
            state.birthDate = value
            state.validationMessage = nil
            if state.scenario != .loading {
                state.scenario = .ideal
            }
        case .updateBirthHour(let value):
            state.birthHourLabel = value
            state.validationMessage = nil
        case .updateGender(let value):
            state.gender = value
            state.validationMessage = nil
        case .updateCalendar(let value):
            state.calendarType = value
            if value != "农历" {
                state.isLeapMonth = false
            }
            state.validationMessage = nil
        case .updateLeapMonth(let value):
            state.isLeapMonth = value
            state.validationMessage = nil
        case .save:
            Task { await saveProfile() }
        case .back:
            router?.closeProfileEditor(saved: false)
        }
    }

    private func saveProfile() async {
        guard FortuneValidation.isValidDate(state.birthDate) else {
            state = ProfileEditorMockFactory.error(from: state, message: "请先选择有效的出生日期，再保存命主档案。")
            return
        }

        let currentState = state
        state = ProfileEditorMockFactory.loading(from: currentState)

        let formatter = ISO8601DateFormatter()
        let profile = ProfileSnapshot(
            profileId: "profile-main",
            birthDate: currentState.birthDate.trimmingCharacters(in: .whitespacesAndNewlines),
            birthHourLabel: currentState.birthHourLabel,
            gender: currentState.gender,
            calendarType: currentState.calendarType,
            isLeapMonth: currentState.calendarType == "农历" ? currentState.isLeapMonth : false,
            lastUpdatedAt: formatter.string(from: nowProvider())
        )

        do {
            try await profileStore.saveProfile(profile)
            var successState = ProfileEditorMockFactory.ideal(profile: profile)
            successState.validationMessage = FortuneProductCopy.profileRefreshMessage
            state = successState
            try? await Task.sleep(nanoseconds: 900_000_000)
            router?.closeProfileEditor(saved: true)
        } catch {
            state = ProfileEditorMockFactory.error(from: currentState, message: error.localizedDescription)
        }
    }
}

struct ProfileEditorView: View {
    @ObservedObject var viewModel: ProfileEditorViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [FortuneTheme.Palette.canvasTop, FortuneTheme.Palette.canvasBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    headerCard
                    formCard
                    noteCard

                    if let validationMessage = viewModel.state.validationMessage {
                        FortuneInlineNotice(
                            message: validationMessage,
                            tone: viewModel.state.scenario == .error ? .error : .info
                        )
                    }

                    Button {
                        viewModel.send(.save)
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.state.scenario == .loading {
                                ProgressView()
                                    .tint(FortuneTheme.Palette.textOnDark)
                            }
                            Text(viewModel.state.saveButtonTitle)
                        }
                    }
                    .buttonStyle(FortunePrimaryButtonStyle())

                    Button(viewModel.state.backButtonTitle) {
                        viewModel.send(.back)
                    }
                    .buttonStyle(FortuneSecondaryButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.refreshIfNeeded()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.state.title)
                        .font(FortuneTheme.Typography.sectionTitle)
                        .foregroundStyle(FortuneTheme.Palette.textPrimary)
                        .minimumScaleFactor(0.9)

                    Text(viewModel.state.subtitle)
                        .font(FortuneTheme.Typography.body)
                        .foregroundStyle(FortuneTheme.Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                FortuneReferenceBadge()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(hex: 0xF3E5CF))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: 0xB48A51), lineWidth: 1)
        )
    }

    private var formCard: some View {
        VStack(spacing: 10) {
            labeledDateField(
                title: "出生日期",
                text: $viewModel.state.birthDate,
                requiredBadge: "必填"
            )

            menuRow(
                title: "出生时辰",
                value: viewModel.state.birthHourLabel,
                options: FortuneFieldCatalog.hourOptions,
                requiredBadge: "必填"
            ) {
                viewModel.send(.updateBirthHour($0))
            }

            menuRow(
                title: "生理性别",
                value: viewModel.state.gender,
                options: FortuneFieldCatalog.genders,
                requiredBadge: "必填"
            ) {
                viewModel.send(.updateGender($0))
            }

            menuRow(
                title: "历法",
                value: viewModel.state.calendarType,
                options: FortuneFieldCatalog.calendars,
                requiredBadge: "必填"
            ) {
                viewModel.send(.updateCalendar($0))
            }

            if viewModel.state.calendarType == "农历" {
                menuRow(
                    title: "农历月别",
                    value: viewModel.state.isLeapMonth ? "闰月" : "平月",
                    options: ["平月", "闰月"],
                    requiredBadge: "按需"
                ) {
                    viewModel.send(.updateLeapMonth($0 == "闰月"))
                }
            }
        }
        .padding(12)
        .background(Color(hex: 0xF8F1E5))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: 0xA67D47), lineWidth: 1)
        )
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.state.noteTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: 0xE6D5B6))

            Text(viewModel.state.noteBody)
                .font(FortuneTheme.Typography.body)
                .foregroundStyle(Color(hex: 0xCDB58D))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(hex: 0x1A140D))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: 0x4A3A25), lineWidth: 1)
        )
    }

    private func labeledDateField(
        title: String,
        text: Binding<String>,
        requiredBadge: String? = nil
    ) -> some View {
        VStack(spacing: 6) {
            FortuneFieldHeader(title: title, requiredBadge: requiredBadge, tone: .light)

            FortuneCompactBirthDateField(text: text, tone: .light, isEnabled: viewModel.state.scenario != .loading)
        }
    }

    private func menuRow(
        title: String,
        value: String,
        options: [String],
        requiredBadge: String? = nil,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        VStack(spacing: 6) {
            FortuneFieldHeader(title: title, requiredBadge: requiredBadge, tone: .light)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        onSelect(option)
                    }
                }
            } label: {
                HStack {
                    Text(value)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x8D6B43))
                }
                .fortuneInputChrome(tone: .light)
            }
            .buttonStyle(.plain)
        }
    }
}
