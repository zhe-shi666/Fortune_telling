import Foundation

enum TodayOverviewMockFactory {
    static func make(_ scenario: MockScenario) -> TodayOverviewState {
        switch scenario {
        case .ideal:
            makeIdeal(from: .sample(for: .sample, on: Date()))
        case .loading:
            makeLoading()
        case .empty:
            makeEmpty()
        case .error:
            makeError(message: "今日参考暂未成功生成，请稍后再试。")
        }
    }

    static func makeIdeal(from payload: DailyFortunePayload) -> TodayOverviewState {
        TodayOverviewState(
            scenario: .ideal,
            quickActions: baseQuickActions,
            hero: TodayHeroContent(title: payload.heroTitle, subtitle: payload.heroSubtitle),
            stemBranch: DailyStemBranchContent(
                label: payload.ganzhiLabel,
                value: payload.ganzhiValue,
                updateHint: payload.updateHint
            ),
            guidance: ActivityGuidanceContent(
                title: "今日宜忌",
                recommendedLine: payload.recommendedLine,
                cautionLine: payload.cautionLine
            ),
            oraclePreview: OraclePreviewContent(
                title: payload.oracleTitle,
                summary: payload.oraclePreview
            ),
            oracleDetail: OracleDetailContent(
                title: payload.oracleDetail.title,
                category: payload.oracleDetail.category,
                body: payload.oracleDetail.body,
                adviceTitle: payload.oracleDetail.adviceTitle,
                adviceBody: payload.oracleDetail.adviceBody,
                triggerHint: payload.oracleDetail.triggerHint,
                secondaryButtonTitle: payload.oracleDetail.secondaryButtonTitle,
                primaryButtonTitle: payload.oracleDetail.primaryButtonTitle
            ),
            profilePrompt: nil,
            errorContent: nil,
            tabs: TodayPrimaryTab.allCases,
            activeTab: .daily,
            inlineMessage: nil,
            isOracleSheetPresented: false,
            isRefreshing: false
        )
    }

    static func makeLoading() -> TodayOverviewState {
        var state = makeIdeal(from: .sample(for: .sample, on: Date()))
        state.scenario = .loading
        state.isRefreshing = true
        return state
    }

    static func makeEmpty() -> TodayOverviewState {
        TodayOverviewState(
            scenario: .empty,
            quickActions: baseQuickActions,
            hero: TodayHeroContent(
                title: "黄历今朝",
                subtitle: "先补全命主档案，再为你整理专属的今日娱乐参考。"
            ),
            stemBranch: nil,
            guidance: nil,
            oraclePreview: nil,
            oracleDetail: nil,
            profilePrompt: ProfilePromptContent(
                title: "命主档案尚未完整",
                body: "今日、八字、取名与合婚都依赖出生日期、时辰、性别与历法，请先进入档案页保存。",
                primaryButtonTitle: "前往填写命主档案"
            ),
            errorContent: nil,
            tabs: TodayPrimaryTab.allCases,
            activeTab: .daily,
            inlineMessage: nil,
            isOracleSheetPresented: false,
            isRefreshing: false
        )
    }

    static func makeError(message: String) -> TodayOverviewState {
        TodayOverviewState(
            scenario: .error,
            quickActions: baseQuickActions,
            hero: TodayHeroContent(
                title: "黄历今朝",
                subtitle: "今日参考暂未成功载入，稍后可再次尝试。"
            ),
            stemBranch: nil,
            guidance: nil,
            oraclePreview: nil,
            oracleDetail: nil,
            profilePrompt: nil,
            errorContent: ErrorCardContent(
                title: "暂时无法整理今日参考",
                message: message,
                retryButtonTitle: "重新载入"
            ),
            tabs: TodayPrimaryTab.allCases,
            activeTab: .daily,
            inlineMessage: nil,
            isOracleSheetPresented: false,
            isRefreshing: false
        )
    }

    private static let baseQuickActions = TodayQuickActionLabels(
        profileShortTitle: "档",
        rechargeShortTitle: "充",
        oracleButtonTitle: "解签",
        oracleButtonSymbol: "✦"
    )
}
