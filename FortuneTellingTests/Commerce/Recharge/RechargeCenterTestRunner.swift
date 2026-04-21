import XCTest
@testable import FortuneTelling

final class RechargeCenterTestRunner: XCTestCase {
    func testEntitlementConsumptionUsesSwiftDataRepository() async throws {
        let repository = SwiftDataFortuneRepository.makeInMemoryRepository()
        let service = SwiftDataFortuneEntitlementService(repository: repository)

        let initial = await service.loadSnapshot()
        let consumed = try await service.consumeIfNeeded(for: .oracle)

        XCTAssertEqual(consumed.jadeBalance, initial.jadeBalance - 1)

        _ = await service.setVIPActive(true)
        let vipBefore = await service.loadSnapshot()
        let vipAfter = try await service.consumeIfNeeded(for: .naming)

        XCTAssertEqual(vipBefore.jadeBalance, vipAfter.jadeBalance)
        XCTAssertTrue(vipAfter.isVIPActive)
    }

    func testRechargeCenterSubmitReturnsProductStyleHoldingMessage() async throws {
        let service = LocalRechargeCenterService(entitlementService: InMemoryFortuneEntitlementService())

        let message = try await service.submitRecharge(planId: "member", paymentMethodId: "wechat")

        XCTAssertEqual(message, FortuneProductCopy.rechargeHoldingMessage)
    }
}
