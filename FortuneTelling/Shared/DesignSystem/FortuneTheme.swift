import SwiftUI

enum FortuneTheme {
    enum Palette {
        static let canvasTop = Color(hex: 0x120F0C)
        static let canvasBottom = Color(hex: 0x1F1812)
        static let shadow = Color.black.opacity(0.18)
        static let paper = Color(hex: 0xF6EFE2)
        static let paperSecondary = Color(hex: 0xFBF6EC)
        static let paperTertiary = Color(hex: 0xF8F1E5)
        static let panel = Color(hex: 0x1A140D)
        static let panelMuted = Color(hex: 0x2A2118)
        static let border = Color(hex: 0xA67D47)
        static let borderLight = Color(hex: 0xD1B083)
        static let accent = Color(hex: 0x8A6433)
        static let accentStrong = Color(hex: 0xB47A34)
        static let accentMuted = Color(hex: 0xE7D2AC)
        static let textPrimary = Color(hex: 0x2A1E12)
        static let textSecondary = Color(hex: 0x5A4530)
        static let textOnDark = Color(hex: 0xF8EED7)
        static let textMutedOnDark = Color(hex: 0xBFAE8C)
        static let success = Color(hex: 0x315A2B)
        static let caution = Color(hex: 0x7A2F2F)
    }

    enum Typography {
        static let heroTitle = Font.system(size: 31, weight: .semibold, design: .serif)
        static let sectionTitle = Font.system(size: 28, weight: .semibold, design: .serif)
        static let cardTitle = Font.system(size: 18, weight: .semibold, design: .serif)
        static let body = Font.system(size: 16, weight: .regular, design: .serif)
        static let bodyStrong = Font.system(size: 19, weight: .medium, design: .serif)
        static let label = Font.system(size: 14, weight: .semibold)
        static let caption = Font.system(size: 12, weight: .semibold)
        static let small = Font.system(size: 11, weight: .semibold)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
