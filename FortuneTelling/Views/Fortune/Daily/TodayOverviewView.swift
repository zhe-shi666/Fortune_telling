import SwiftUI

struct TodayOverviewView: View {
    @ObservedObject var viewModel: TodayOverviewViewModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [FortuneTheme.Palette.canvasTop, FortuneTheme.Palette.canvasBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    heroCard

                    if let inlineMessage = viewModel.state.inlineMessage {
                        FortuneInlineNotice(message: inlineMessage, tone: .info)
                    }

                    scenarioContent
                }
                .padding(.horizontal, 16)
                .padding(.top, 48)
                .padding(.bottom, 24)
            }

            quickActions
        }
        .safeAreaInset(edge: .bottom) {
            bottomChrome
        }
        .overlay {
            if viewModel.state.isOracleSheetPresented, let detail = viewModel.state.oracleDetail {
                oracleOverlay(detail: detail)
            }
        }
        .task {
            await viewModel.refreshIfNeeded()
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(FortuneTheme.Palette.borderLight)
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)

                Text("◈")
                    .font(FortuneTheme.Typography.caption)
                    .foregroundStyle(FortuneTheme.Palette.accent)

                Rectangle()
                    .fill(FortuneTheme.Palette.borderLight)
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(viewModel.state.hero.title)
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .foregroundStyle(FortuneTheme.Palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)

                Spacer(minLength: 8)

                FortuneReferenceBadge()
                    .fixedSize()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("今日摘要")
                    .font(FortuneTheme.Typography.caption)
                    .foregroundStyle(FortuneTheme.Palette.accent)

                Text(viewModel.state.hero.subtitle)
                    .font(FortuneTheme.Typography.body)
                    .foregroundStyle(FortuneTheme.Palette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(FortuneTheme.Palette.paper)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(FortuneTheme.Palette.border, lineWidth: 1)
        )
        .shadow(color: FortuneTheme.Palette.shadow, radius: 10, y: 4)
    }

    @ViewBuilder
    private var scenarioContent: some View {
        switch viewModel.state.scenario {
        case .ideal:
            readingCards(redacted: false)
        case .loading:
            readingCards(redacted: true)
        case .empty:
            if let prompt = viewModel.state.profilePrompt {
                promptCard(prompt)
            }
        case .error:
            if let errorContent = viewModel.state.errorContent {
                errorCard(errorContent)
            }
        }
    }

    @ViewBuilder
    private func readingCards(redacted: Bool) -> some View {
        if let stemBranch = viewModel.state.stemBranch {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(stemBranch.label)
                        .font(FortuneTheme.Typography.label)
                        .foregroundStyle(FortuneTheme.Palette.textSecondary)

                    Spacer()

                    Text(stemBranch.updateHint)
                        .font(FortuneTheme.Typography.caption)
                        .foregroundStyle(FortuneTheme.Palette.textSecondary.opacity(0.75))
                }

                Text(stemBranch.value)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(FortuneTheme.Palette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(FortuneTheme.Palette.paperSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(FortuneTheme.Palette.border, lineWidth: 1)
            )
            .redacted(reason: redacted ? .placeholder : [])
        }

        if let guidance = viewModel.state.guidance {
            VStack(alignment: .leading, spacing: 8) {
                Text(guidance.title)
                    .font(FortuneTheme.Typography.label)
                    .foregroundStyle(FortuneTheme.Palette.textSecondary)

                guidanceBubble("宜", text: guidance.recommendedLine, tint: FortuneTheme.Palette.success, fill: .white.opacity(0.82))
                guidanceBubble("忌", text: guidance.cautionLine, tint: FortuneTheme.Palette.caution, fill: Color(hex: 0xFFF7F1))
            }
            .padding(14)
            .background(FortuneTheme.Palette.paperTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(FortuneTheme.Palette.border, lineWidth: 1)
            )
            .redacted(reason: redacted ? .placeholder : [])
        }

        if let oraclePreview = viewModel.state.oraclePreview {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(oraclePreview.title)
                        .font(FortuneTheme.Typography.caption)
                        .foregroundStyle(FortuneTheme.Palette.accent)

                    Text(oraclePreview.summary)
                        .font(FortuneTheme.Typography.body)
                        .foregroundStyle(FortuneTheme.Palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .padding(.bottom, 10)
                .background(Color(hex: 0xF3E5CF))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: 0xB48A51), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 16, y: 8)

                HStack {
                    Spacer()
                    oracleActionButton
                }
            }
            .redacted(reason: redacted ? .placeholder : [])
        }
    }

    private func guidanceBubble(_ title: String, text: String, tint: Color, fill: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(FortuneTheme.Typography.caption)
                .foregroundStyle(tint.opacity(0.9))

            Text(text)
                .font(FortuneTheme.Typography.body)
                .foregroundStyle(tint)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(FortuneTheme.Palette.borderLight, lineWidth: 1)
        )
    }

    private var oracleActionButton: some View {
        Button {
            guard viewModel.state.oracleDetail != nil else { return }
            viewModel.send(.presentOracle(true))
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.state.quickActions.oracleButtonSymbol)
                Text(viewModel.state.quickActions.oracleButtonTitle)
            }
            .font(FortuneTheme.Typography.small)
            .foregroundStyle(FortuneTheme.Palette.textOnDark)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(FortuneTheme.Palette.accentStrong)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(hex: 0xE2C89A), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.state.oracleDetail == nil)
        .opacity(viewModel.state.oracleDetail == nil ? 0.4 : 1)
    }

    private func promptCard(_ content: ProfilePromptContent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(content.title)
                .font(FortuneTheme.Typography.cardTitle)
                .foregroundStyle(FortuneTheme.Palette.textPrimary)

            Text(content.body)
                .font(FortuneTheme.Typography.body)
                .foregroundStyle(FortuneTheme.Palette.textSecondary)

            Button(content.primaryButtonTitle) {
                viewModel.send(.openProfile)
            }
            .buttonStyle(FortunePrimaryButtonStyle())
        }
        .padding(16)
        .background(FortuneTheme.Palette.paperTertiary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(FortuneTheme.Palette.border, lineWidth: 1)
        )
    }

    private func errorCard(_ content: ErrorCardContent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(content.title)
                .font(FortuneTheme.Typography.cardTitle)
                .foregroundStyle(FortuneTheme.Palette.textPrimary)

            Text(content.message)
                .font(FortuneTheme.Typography.body)
                .foregroundStyle(FortuneTheme.Palette.textSecondary)

            Button(content.retryButtonTitle) {
                viewModel.send(.retryLoad)
            }
            .buttonStyle(FortunePrimaryButtonStyle())
        }
        .padding(16)
        .background(FortuneTheme.Palette.paperTertiary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(FortuneTheme.Palette.border, lineWidth: 1)
        )
    }

    private var quickActions: some View {
        HStack(spacing: 6) {
            iconChip(viewModel.state.quickActions.profileShortTitle) {
                viewModel.send(.openProfile)
            }

            iconChip(viewModel.state.quickActions.rechargeShortTitle) {
                viewModel.send(.openRecharge)
            }
        }
        .padding(.top, 8)
        .padding(.trailing, 16)
    }

    private func iconChip(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(FortuneTheme.Typography.small)
                .foregroundStyle(Color(hex: 0x6A4A24))
                .frame(width: 28, height: 28)
                .background(FortuneTheme.Palette.accentMuted)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(FortuneTheme.Palette.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var bottomChrome: some View {
        VStack(spacing: 12) {
            HStack(spacing: 18) {
                FortuneMainTabBar(selectedTab: viewModel.state.activeTab, showsBackground: false) { tab in
                    viewModel.send(.openTab(tab))
                }
            }
            .padding(.horizontal, 21)
            .padding(.vertical, 1)
            .background(Color(hex: 0xEFE2CC))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(FortuneTheme.Palette.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 12, y: 4)
            .padding(.horizontal, 24)
            .padding(.bottom, 6)
        }
        .background(Color.clear)
    }

    private func oracleOverlay(detail: OracleDetailContent) -> some View {
        ZStack {
            Color.black.opacity(0.48)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.send(.presentOracle(false))
                }

            FortunePopupSurface(tone: .light, maxWidth: 358) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(detail.title)
                            .font(FortuneTheme.Typography.cardTitle)
                            .foregroundStyle(Color(hex: 0x6F4A24))

                        Spacer()

                        Button("✕") {
                            viewModel.send(.presentOracle(false))
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x9B7543))
                        .buttonStyle(.plain)
                    }

                    Rectangle()
                        .fill(Color(hex: 0xD9BE93))
                        .frame(height: 1)

                    Text(detail.category)
                        .font(FortuneTheme.Typography.label)
                        .foregroundStyle(Color(hex: 0x8A6333))

                    Text(detail.body)
                        .font(FortuneTheme.Typography.body)
                        .foregroundStyle(Color(hex: 0x5E4324))
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(detail.adviceTitle)
                            .font(FortuneTheme.Typography.caption)
                            .foregroundStyle(Color(hex: 0x8A6333))

                        Text(detail.adviceBody)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: 0x7C5930))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .background(Color(hex: 0xF2DFC2))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(hex: 0xC9A470), lineWidth: 1)
                    )

                    Label(detail.triggerHint, systemImage: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x8A6333))

                    HStack(spacing: 10) {
                        Button(detail.secondaryButtonTitle) {
                            viewModel.send(.presentOracle(false))
                        }
                        .buttonStyle(FortuneSecondaryButtonStyle())

                        Button(detail.primaryButtonTitle) {
                            viewModel.send(.presentOracle(false))
                        }
                        .buttonStyle(FortunePrimaryButtonStyle())
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
        .animation(.easeInOut(duration: 0.22), value: viewModel.state.isOracleSheetPresented)
    }
}
