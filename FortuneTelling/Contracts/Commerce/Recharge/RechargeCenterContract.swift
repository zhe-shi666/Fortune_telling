import Foundation

struct RechargePlanContent: Equatable, Sendable, Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var priceText: String
    var isSelected: Bool
}

struct RechargePaymentMethodContent: Equatable, Sendable, Identifiable {
    var id: String
    var title: String
    var statusText: String
    var isSelected: Bool
    var dotHex: UInt32
}

struct RechargeCenterState: Equatable, Sendable {
    var scenario: MockScenario
    var balanceLabel: String
    var balanceValue: String
    var membershipValue: String
    var balanceHint: String
    var plansTitle: String
    var plans: [RechargePlanContent]
    var paymentMethodsTitle: String
    var paymentMethods: [RechargePaymentMethodContent]
    var agreementText: String
    var rechargeButtonTitle: String
    var backButtonTitle: String
    var inlineMessage: String?
}

enum RechargeCenterAction: Equatable, Sendable {
    case selectPlan(String)
    case selectPaymentMethod(String)
    case submitRecharge
    case back
}
