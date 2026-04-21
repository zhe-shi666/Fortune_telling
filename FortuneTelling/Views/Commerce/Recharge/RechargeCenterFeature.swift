import SwiftUI

struct FortuneEntitlementSnapshot: Equatable, Sendable {
    var jadeBalance: Int
    var isVIPActive: Bool

    var membershipValue: String {
        isVIPActive ? "VIP 畅用中" : "按次消耗"
    }

    var usageHint: String {
        FortuneProductCopy.usageRule()
    }
}

enum FortuneUsageFeature: String, Equatable, Sendable {
    case oracle
    case bazi
    case naming
    case compatibility

    var displayName: String {
        switch self {
        case .oracle:
            "解签"
        case .bazi:
            "合取测算"
        case .naming:
            "取名"
        case .compatibility:
            "合婚推演"
        }
    }
}

enum FortuneEntitlementError: LocalizedError, Equatable, Sendable {
    case insufficientJade(FortuneUsageFeature)

    var errorDescription: String? {
        switch self {
        case .insufficientJade(let feature):
            FortuneProductCopy.insufficientJadeMessage(for: feature)
        }
    }
}

protocol FortuneEntitlementServicing: Sendable {
    func loadSnapshot() async -> FortuneEntitlementSnapshot
    func consumeIfNeeded(for feature: FortuneUsageFeature) async throws -> FortuneEntitlementSnapshot
    func grantJade(_ amount: Int) async -> FortuneEntitlementSnapshot
    func setVIPActive(_ isActive: Bool) async -> FortuneEntitlementSnapshot
}

actor SwiftDataFortuneEntitlementService: FortuneEntitlementServicing {
    private let repository: any FortuneLocalRepositorying

    init(repository: any FortuneLocalRepositorying = SwiftDataFortuneRepository.shared) {
        self.repository = repository
    }

    func loadSnapshot() async -> FortuneEntitlementSnapshot {
        do {
            return try await repository.loadEntitlement()
        } catch {
            return FortuneEntitlementSnapshot(jadeBalance: 0, isVIPActive: false)
        }
    }

    func consumeIfNeeded(for feature: FortuneUsageFeature) async throws -> FortuneEntitlementSnapshot {
        try await repository.consumeEntitlement(for: feature)
    }

    func grantJade(_ amount: Int) async -> FortuneEntitlementSnapshot {
        do {
            return try await repository.grantJade(amount)
        } catch {
            return await loadSnapshot()
        }
    }

    func setVIPActive(_ isActive: Bool) async -> FortuneEntitlementSnapshot {
        do {
            return try await repository.setVIPActive(isActive)
        } catch {
            return await loadSnapshot()
        }
    }
}

actor InMemoryFortuneEntitlementService: FortuneEntitlementServicing {
    private var snapshot: FortuneEntitlementSnapshot

    init(jadeBalance: Int = 1_288, isVIPActive: Bool = false) {
        self.snapshot = FortuneEntitlementSnapshot(jadeBalance: jadeBalance, isVIPActive: isVIPActive)
    }

    func loadSnapshot() async -> FortuneEntitlementSnapshot {
        snapshot
    }

    func consumeIfNeeded(for feature: FortuneUsageFeature) async throws -> FortuneEntitlementSnapshot {
        if snapshot.isVIPActive {
            return snapshot
        }
        guard snapshot.jadeBalance > 0 else {
            throw FortuneEntitlementError.insufficientJade(feature)
        }
        snapshot.jadeBalance -= 1
        return snapshot
    }

    func grantJade(_ amount: Int) async -> FortuneEntitlementSnapshot {
        snapshot.jadeBalance += max(amount, 0)
        return snapshot
    }

    func setVIPActive(_ isActive: Bool) async -> FortuneEntitlementSnapshot {
        snapshot.isVIPActive = isActive
        return snapshot
    }

    func reset(jadeBalance: Int = 1_288, isVIPActive: Bool = false) async {
        snapshot = FortuneEntitlementSnapshot(jadeBalance: jadeBalance, isVIPActive: isVIPActive)
    }
}

actor UserDefaultsFortuneEntitlementService: FortuneEntitlementServicing {
    private let suiteName: String?
    private let jadeBalanceKey: String
    private let vipActiveKey: String
    private let defaultBalance: Int

    init(
        suiteName: String? = nil,
        jadeBalanceKey: String = "fortune.entitlement.jade.balance.v1",
        vipActiveKey: String = "fortune.entitlement.vip.active.v1",
        defaultBalance: Int = 1_288
    ) {
        self.suiteName = suiteName
        self.jadeBalanceKey = jadeBalanceKey
        self.vipActiveKey = vipActiveKey
        self.defaultBalance = defaultBalance
    }

    func loadSnapshot() async -> FortuneEntitlementSnapshot {
        FortuneEntitlementSnapshot(
            jadeBalance: storedBalance,
            isVIPActive: defaults().bool(forKey: vipActiveKey)
        )
    }

    func consumeIfNeeded(for feature: FortuneUsageFeature) async throws -> FortuneEntitlementSnapshot {
        let snapshot = await loadSnapshot()
        if snapshot.isVIPActive {
            return snapshot
        }
        guard snapshot.jadeBalance > 0 else {
            throw FortuneEntitlementError.insufficientJade(feature)
        }
        defaults().set(snapshot.jadeBalance - 1, forKey: jadeBalanceKey)
        return await loadSnapshot()
    }

    func grantJade(_ amount: Int) async -> FortuneEntitlementSnapshot {
        let nextBalance = storedBalance + max(amount, 0)
        defaults().set(nextBalance, forKey: jadeBalanceKey)
        return await loadSnapshot()
    }

    func setVIPActive(_ isActive: Bool) async -> FortuneEntitlementSnapshot {
        defaults().set(isActive, forKey: vipActiveKey)
        return await loadSnapshot()
    }

    func clear() async {
        defaults().removeObject(forKey: jadeBalanceKey)
        defaults().removeObject(forKey: vipActiveKey)
    }

    private var storedBalance: Int {
        guard defaults().object(forKey: jadeBalanceKey) != nil else {
            return defaultBalance
        }
        return defaults().integer(forKey: jadeBalanceKey)
    }

    private func defaults() -> UserDefaults {
        guard let suiteName, let defaults = UserDefaults(suiteName: suiteName) else {
            return .standard
        }
        return defaults
    }
}

enum FortuneEntitlementFormatter {
    static let jadeBalance: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    static func balanceText(_ balance: Int) -> String {
        jadeBalance.string(from: NSNumber(value: balance)) ?? "\(balance)"
    }
}

struct RechargeCenterPayload: Equatable, Sendable {
    var balanceValue: String
    var membershipValue: String
    var usageHint: String
    var plans: [RechargePlanContent]
    var paymentMethods: [RechargePaymentMethodContent]
}

enum RechargeCenterServiceError: LocalizedError, Equatable, Sendable {
    case unavailable
    case nothingSelected

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "当前未能读取购买信息，请稍后再试。"
        case .nothingSelected:
            "请先选择一个购买方案和支付方式，再继续查看购买说明。"
        }
    }
}

protocol RechargeCenterServicing: Sendable {
    func loadCenter() async throws -> RechargeCenterPayload
    func submitRecharge(planId: String, paymentMethodId: String) async throws -> String
}

actor LocalRechargeCenterService: RechargeCenterServicing {
    private let entitlementService: any FortuneEntitlementServicing
    private let resetEntitlements: (@Sendable () async -> Void)?

    init(
        suiteName: String? = nil,
        entitlementService: (any FortuneEntitlementServicing)? = nil
    ) {
        if let entitlementService {
            self.entitlementService = entitlementService
            self.resetEntitlements = nil
        } else {
            let service = UserDefaultsFortuneEntitlementService(suiteName: suiteName)
            self.entitlementService = service
            self.resetEntitlements = {
                await service.clear()
            }
        }
    }

    func loadCenter() async throws -> RechargeCenterPayload {
        let snapshot = await entitlementService.loadSnapshot()
        return RechargeCenterPayload(
            balanceValue: FortuneEntitlementFormatter.balanceText(snapshot.jadeBalance),
            membershipValue: snapshot.membershipValue,
            usageHint: snapshot.usageHint,
            plans: [
                RechargePlanContent(id: "single", title: "灵玉小补给", subtitle: "正式开放后可补充灵玉，用于单次解签与测算。", priceText: "¥1/次", isSelected: false),
                RechargePlanContent(id: "member", title: "VIP 畅用卡", subtitle: "正式开放后可无限使用解签、合取测算、合婚推演与取名。", priceText: "¥10/月", isSelected: true)
            ],
            paymentMethods: [
                RechargePaymentMethodContent(id: "wechat", title: "微信支付", statusText: "已选", isSelected: true, dotHex: 0x21C45D),
                RechargePaymentMethodContent(id: "alipay", title: "支付宝", statusText: "未选", isSelected: false, dotHex: 0x7C97D6)
            ]
        )
    }

    func submitRecharge(planId: String, paymentMethodId: String) async throws -> String {
        guard ["single", "member"].contains(planId),
              ["wechat", "alipay"].contains(paymentMethodId) else {
            throw RechargeCenterServiceError.unavailable
        }
        return FortuneProductCopy.rechargeHoldingMessage
    }

    func clear() async {
        await resetEntitlements?()
    }
}

struct MockRechargeCenterService: RechargeCenterServicing {
    enum Behavior: Sendable {
        case success
        case failure(RechargeCenterServiceError)
    }

    var behavior: Behavior = .success

    func loadCenter() async throws -> RechargeCenterPayload {
        switch behavior {
        case .success:
            return RechargeCenterPayload(
                balanceValue: "1,288",
                membershipValue: "按次消耗",
                usageHint: "解签、合取测算、合婚推演与取名每次消耗 1 灵玉；开通 VIP 后可无限使用。",
                plans: [
                    RechargePlanContent(id: "single", title: "灵玉小补给", subtitle: "正式开放后可补充灵玉，用于单次解签与测算。", priceText: "¥1/次", isSelected: false),
                    RechargePlanContent(id: "member", title: "VIP 畅用卡", subtitle: "正式开放后可无限使用解签、合取测算、合婚推演与取名。", priceText: "¥10/月", isSelected: true)
                ],
                paymentMethods: [
                    RechargePaymentMethodContent(id: "wechat", title: "微信支付", statusText: "已选", isSelected: true, dotHex: 0x21C45D),
                    RechargePaymentMethodContent(id: "alipay", title: "支付宝", statusText: "未选", isSelected: false, dotHex: 0x7C97D6)
                ]
            )
        case .failure(let error):
            throw error
        }
    }

    func submitRecharge(planId: String, paymentMethodId: String) async throws -> String {
        switch behavior {
        case .success:
            return FortuneProductCopy.rechargeHoldingMessage
        case .failure(let error):
            throw error
        }
    }
}

@MainActor
protocol RechargeCenterRouting: AnyObject {
    func closeRechargeCenter()
}

enum RechargeCenterMockFactory {
    static func loading() -> RechargeCenterState {
        RechargeCenterState(
            scenario: .loading,
            balanceLabel: "当前灵玉与权益",
            balanceValue: "----",
            membershipValue: "读取中",
            balanceHint: FortuneProductCopy.usageRule(),
            plansTitle: "内购方案",
            plans: [],
            paymentMethodsTitle: "支付方式",
            paymentMethods: [],
            agreementText: FortuneProductCopy.rechargeHoldingMessage,
            rechargeButtonTitle: "查看购买说明",
            backButtonTitle: "返回今日",
            inlineMessage: nil
        )
    }

    static func ideal(from payload: RechargeCenterPayload) -> RechargeCenterState {
        RechargeCenterState(
            scenario: .ideal,
            balanceLabel: "当前灵玉与权益",
            balanceValue: payload.balanceValue,
            membershipValue: payload.membershipValue,
            balanceHint: payload.usageHint,
            plansTitle: "内购方案",
            plans: payload.plans,
            paymentMethodsTitle: "支付方式",
            paymentMethods: payload.paymentMethods,
            agreementText: FortuneProductCopy.rechargeHoldingMessage,
            rechargeButtonTitle: "查看购买说明",
            backButtonTitle: "返回今日",
            inlineMessage: nil
        )
    }

    static func error(from state: RechargeCenterState, message: String) -> RechargeCenterState {
        var next = state
        next.scenario = .error
        next.inlineMessage = message
        return next
    }
}

@MainActor
final class RechargeCenterViewModel: ObservableObject {
    @Published var state: RechargeCenterState
    weak var router: (any RechargeCenterRouting)?

    private let service: any RechargeCenterServicing
    private var hasLoaded = false

    init(
        service: any RechargeCenterServicing,
        initialState: RechargeCenterState = RechargeCenterMockFactory.loading(),
        router: (any RechargeCenterRouting)? = nil
    ) {
        self.service = service
        self.state = initialState
        self.router = router
    }

    func refreshIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await refresh()
    }

    func refresh() async {
        state = RechargeCenterMockFactory.loading()

        do {
            let payload = try await service.loadCenter()
            state = RechargeCenterMockFactory.ideal(from: payload)
        } catch {
            state = RechargeCenterMockFactory.error(from: state, message: error.localizedDescription)
        }
    }

    func send(_ action: RechargeCenterAction) {
        switch action {
        case .selectPlan(let planId):
            state.plans = state.plans.map { plan in
                var next = plan
                next.isSelected = plan.id == planId
                return next
            }
            state.inlineMessage = nil
        case .selectPaymentMethod(let methodId):
            state.paymentMethods = state.paymentMethods.map { method in
                var next = method
                next.isSelected = method.id == methodId
                next.statusText = next.isSelected ? "已选" : "未选"
                return next
            }
            state.inlineMessage = nil
        case .submitRecharge:
            Task { await submitRecharge() }
        case .back:
            router?.closeRechargeCenter()
        }
    }

    private func submitRecharge() async {
        guard let selectedPlan = state.plans.first(where: \.isSelected),
              let selectedMethod = state.paymentMethods.first(where: \.isSelected) else {
            state.inlineMessage = RechargeCenterServiceError.nothingSelected.localizedDescription
            state.scenario = .error
            return
        }

        let previous = state
        state.scenario = .loading

        do {
            let message = try await service.submitRecharge(planId: selectedPlan.id, paymentMethodId: selectedMethod.id)
            let refreshedPayload = try await service.loadCenter()
            state = RechargeCenterMockFactory.ideal(from: refreshedPayload)
            state.inlineMessage = message
        } catch {
            state = RechargeCenterMockFactory.error(from: previous, message: error.localizedDescription)
        }
    }
}

struct RechargeCenterView: View {
    @ObservedObject var viewModel: RechargeCenterViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0C0906), Color(hex: 0x1A140D)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    balanceCard
                    plansSection
                    paymentSection

                    Text(viewModel.state.agreementText)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: 0x9E8862))

                    if let inlineMessage = viewModel.state.inlineMessage {
                        FortuneInlineNotice(
                            message: inlineMessage,
                            tone: viewModel.state.scenario == .error ? .error : .info
                        )
                    }

                    Button {
                        viewModel.send(.submitRecharge)
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.state.scenario == .loading {
                                ProgressView()
                                    .tint(FortuneTheme.Palette.textOnDark)
                            }
                            Text(viewModel.state.rechargeButtonTitle)
                        }
                    }
                    .buttonStyle(FortunePrimaryButtonStyle())
                    .redacted(reason: viewModel.state.scenario == .loading ? .placeholder : [])

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

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.state.balanceLabel)
                        .font(FortuneTheme.Typography.small)
                        .foregroundStyle(Color(hex: 0xD8C29A))

                    Text(viewModel.state.balanceValue)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color(hex: 0xF8EED7))
                        .minimumScaleFactor(0.82)

                    Text(viewModel.state.membershipValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: 0xF1D18F))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(hex: 0x24180F))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: 0x9B7340), lineWidth: 1)
                        )
                }

                Spacer(minLength: 0)

                FortuneReferenceBadge()
            }

            Text(viewModel.state.balanceHint)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: 0xC8AE82))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x2A1F14), Color(hex: 0x4A3722)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: 0x6B5333), lineWidth: 1)
        )
    }

    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.state.plansTitle)
                .font(FortuneTheme.Typography.label)
                .foregroundStyle(Color(hex: 0xE6D5B6))

            ForEach(viewModel.state.plans) { plan in
                Button {
                    viewModel.send(.selectPlan(plan.id))
                } label: {
                    ViewThatFits(in: .vertical) {
                        HStack(alignment: .top, spacing: 12) {
                            planText(plan)
                            Spacer()
                            planPrice(plan)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            planText(plan)
                            planPrice(plan)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(plan.isSelected ? Color(hex: 0x1F160E) : Color(hex: 0x17110B))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(plan.isSelected ? Color(hex: 0xA47A3E) : Color(hex: 0x4F3D26), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.state.paymentMethodsTitle)
                .font(FortuneTheme.Typography.label)
                .foregroundStyle(Color(hex: 0xE6D5B6))

            ForEach(viewModel.state.paymentMethods) { method in
                Button {
                    viewModel.send(.selectPaymentMethod(method.id))
                } label: {
                    HStack {
                        Circle()
                            .fill(method.isSelected ? Color(hex: method.dotHex) : Color.clear)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: method.dotHex), lineWidth: 1)
                            )

                        Text(method.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: 0xE8D8BA))

                        Spacer()

                        Text(method.statusText)
                            .font(FortuneTheme.Typography.small)
                            .foregroundStyle(method.isSelected ? Color(hex: 0xD9C4A1) : Color(hex: 0x8B7758))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: 0x17110B))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(hex: 0x4F3D26), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func planText(_ plan: RechargePlanContent) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(plan.title)
                .font(FortuneTheme.Typography.label)
                .foregroundStyle(Color(hex: 0xF5E8D2))
            Text(plan.subtitle)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: 0xBCA98A))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func planPrice(_ plan: RechargePlanContent) -> some View {
        Text(plan.priceText)
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.white)
            .minimumScaleFactor(0.8)
    }
}
