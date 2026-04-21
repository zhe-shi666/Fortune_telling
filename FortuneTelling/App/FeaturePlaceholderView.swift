import SwiftUI

struct FeaturePlaceholderView: View {
    let title: String
    let subtitle: String
    let note: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [FortuneTheme.Palette.canvasTop, FortuneTheme.Palette.canvasBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(FortuneTheme.Typography.sectionTitle)
                    .foregroundStyle(FortuneTheme.Palette.textOnDark)

                Text(subtitle)
                    .font(FortuneTheme.Typography.body)
                    .foregroundStyle(FortuneTheme.Palette.textMutedOnDark)

                VStack(alignment: .leading, spacing: 10) {
                    Text("当前轮次说明")
                        .font(FortuneTheme.Typography.label)
                        .foregroundStyle(FortuneTheme.Palette.textPrimary)

                    Text(note)
                        .font(FortuneTheme.Typography.body)
                        .foregroundStyle(FortuneTheme.Palette.textSecondary)
                }
                .padding(16)
                .background(FortuneTheme.Palette.paper)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(FortuneTheme.Palette.border, lineWidth: 1)
                )
            }
            .padding(24)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
