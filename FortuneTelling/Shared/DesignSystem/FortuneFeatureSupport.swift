import SwiftUI

enum FortuneProductCopy {
    static let referenceLabel = "娱乐参考 / 辅助参考"
    static let profileRefreshMessage = "保存成功，今日、八字、合婚与取名会按新档案刷新。"
    static let rechargeHoldingMessage = "当前版本先展示权益与购买说明，正式开放后会通过 App Store 应用内购买安全完成。"

    static func usageRule(for feature: FortuneUsageFeature? = nil) -> String {
        if let feature {
            return "\(feature.displayName) 属于娱乐参考能力；普通用户每次消耗 1 灵玉，VIP 可无限使用。"
        }
        return "解签、合取测算、取名与合婚推演都属于娱乐参考能力；普通用户每次消耗 1 灵玉，VIP 可无限使用。"
    }

    static func insufficientJadeMessage(for feature: FortuneUsageFeature) -> String {
        "当前灵玉不足，\(feature.displayName) 每次需要 1 灵玉；开通 VIP 后可无限使用。"
    }
}

struct FortunePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(FortuneTheme.Palette.textOnDark)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .frame(maxWidth: .infinity, minHeight: 46)
            .padding(.horizontal, 16)
            .background(FortuneTheme.Palette.accent)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: 0xE2C89A), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct FortuneSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color(hex: 0xE6D5B6))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .frame(maxWidth: .infinity, minHeight: 46)
            .padding(.horizontal, 16)
            .background(Color(hex: 0x241B13))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: 0x7A5D38), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct FortuneReferenceBadge: View {
    var body: some View {
        Text(FortuneProductCopy.referenceLabel)
            .font(FortuneTheme.Typography.small)
            .foregroundStyle(Color(hex: 0x8A6333))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color(hex: 0xF2DFC2))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(hex: 0xC9A470), lineWidth: 1)
            )
    }
}

struct FortuneInlineNotice: View {
    let message: String
    let tone: Tone

    enum Tone {
        case error
        case info

        var fill: Color {
            switch self {
            case .error:
                Color(hex: 0xFFF1EF)
            case .info:
                Color(hex: 0xF3E5CF)
            }
        }

        var stroke: Color {
            switch self {
            case .error:
                Color(hex: 0xD59A8F)
            case .info:
                Color(hex: 0xB48A51)
            }
        }

        var text: Color {
            switch self {
            case .error:
                Color(hex: 0x7A2F2F)
            case .info:
                Color(hex: 0x5E4324)
            }
        }
    }

    var body: some View {
        Text(message)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(tone.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(10)
            .background(tone.fill)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(tone.stroke, lineWidth: 1)
            )
    }
}

struct FortuneToastBubble: View {
    let message: String

    var body: some View {
        Text(message)
            .font(FortuneTheme.Typography.small)
            .foregroundStyle(Color(hex: 0xF5ECD8))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(hex: 0x2A1F15, opacity: 0.96))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(hex: 0x6E5A3B), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
    }
}

struct FortuneMainTabBar: View {
    let selectedTab: TodayPrimaryTab
    var showsBackground: Bool = true
    let onSelect: (TodayPrimaryTab) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(TodayPrimaryTab.allCases) { tab in
                Button {
                    onSelect(tab)
                } label: {
                    VStack(spacing: 3) {
                        Text(tab.symbol)
                            .font(.system(size: 14))
                        Text(tab.title)
                            .font(FortuneTheme.Typography.small)
                    }
                    .foregroundStyle(foregroundColor(for: tab))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        backgroundColor(for: tab)
                            .clipShape(Capsule())
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(
            Group {
                if showsBackground {
                    Color(hex: 0x1A140D)
                } else {
                    Color.clear
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .overlay(
            Group {
                if showsBackground {
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(Color(hex: 0x4A3A25), lineWidth: 1)
                }
            }
        )
    }

    private func foregroundColor(for tab: TodayPrimaryTab) -> Color {
        if tab == selectedTab {
            return FortuneTheme.Palette.textOnDark
        }
        return showsBackground ? FortuneTheme.Palette.textMutedOnDark : FortuneTheme.Palette.textSecondary.opacity(0.74)
    }

    private func backgroundColor(for tab: TodayPrimaryTab) -> Color {
        if tab == selectedTab {
            return FortuneTheme.Palette.accent
        }
        return showsBackground ? Color(hex: 0x251D14) : Color.clear
    }
}

enum FortuneFieldTone {
    case light
    case dark

    var labelColor: Color {
        switch self {
        case .light:
            Color(hex: 0x604328)
        case .dark:
            Color(hex: 0xF0DFC2)
        }
    }

    var textColor: Color {
        switch self {
        case .light:
            Color(hex: 0x2F2216)
        case .dark:
            Color(hex: 0xE8D8BA)
        }
    }

    var fillColor: Color {
        switch self {
        case .light:
            Color(hex: 0xFFF9EF)
        case .dark:
            Color(hex: 0x231A13)
        }
    }

    var strokeColor: Color {
        switch self {
        case .light:
            Color(hex: 0xD7B590)
        case .dark:
            Color(hex: 0x6E5A3B)
        }
    }

    var badgeFillColor: Color {
        switch self {
        case .light:
            Color(hex: 0x5C2C28)
        case .dark:
            Color(hex: 0x4D2A25)
        }
    }

    var badgeTextColor: Color {
        Color(hex: 0xF4D1D1)
    }
}

struct FortuneFieldHeader: View {
    let title: String
    var requiredBadge: String? = nil
    var tone: FortuneFieldTone = .dark

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(FortuneTheme.Typography.label)
                .foregroundStyle(tone.labelColor)
                .fixedSize(horizontal: false, vertical: true)

            if let requiredBadge {
                Text(requiredBadge)
                    .font(FortuneTheme.Typography.small)
                    .foregroundStyle(tone.badgeTextColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(tone.badgeFillColor)
                    .clipShape(Capsule())
            }

            Spacer(minLength: 0)
        }
    }
}

struct FortuneFieldHintText: View {
    let text: String
    var tone: FortuneFieldTone = .dark

    var body: some View {
        Text(text)
            .font(FortuneTheme.Typography.small)
            .foregroundStyle(tone == .dark ? Color(hex: 0xBFA57F) : Color(hex: 0x7A6142))
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

extension View {
    func fortuneInputChrome(tone: FortuneFieldTone, minHeight: CGFloat = 48) -> some View {
        self
            .font(.system(size: 16, weight: .medium, design: .serif))
            .foregroundStyle(tone.textColor)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .background(tone.fillColor)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(tone.strokeColor, lineWidth: 1)
            )
    }
}

enum FortuneBirthDateSupport {
    static let storageTimeZone = TimeZone(identifier: "Asia/Shanghai") ?? .autoupdatingCurrent

    static let storageFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = storageTimeZone
        formatter.calendar = calendar
        formatter.timeZone = storageTimeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let displayLocale = Locale(identifier: "zh_CN")
    static let minimumDate = storageFormatter.date(from: "1900-01-01") ?? .distantPast
    static let fallbackDate = storageFormatter.date(from: "2000-01-01") ?? Date()
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = storageTimeZone
        return calendar
    }()
    static let years = Array(1900...(calendar.component(.year, from: Date())))
    static let months = Array(1...12)

    static func resolvedDate(from text: String) -> Date {
        storageFormatter.date(from: text) ?? fallbackDate
    }

    fileprivate static func resolvedComponents(from date: Date) -> FortuneBirthDateComponents {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return FortuneBirthDateComponents(
            year: components.year ?? 2000,
            month: components.month ?? 1,
            day: components.day ?? 1
        )
    }

    static func days(forYear year: Int, month: Int) -> [Int] {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return Array(1...31)
        }

        return Array(range)
    }

    static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components) ?? fallbackDate
    }
}

fileprivate struct FortuneBirthDateComponents: Equatable {
    var year: Int
    var month: Int
    var day: Int
}

struct FortuneCompactBirthDateField: View {
    @Binding var text: String
    var tone: FortuneFieldTone
    var isEnabled: Bool = true
    @State private var isPickerPresented = false

    var body: some View {
        Button {
            guard isEnabled else { return }
            isPickerPresented = true
        } label: {
            HStack(spacing: 8) {
                Text(displayText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tone.textColor.opacity(0.9))

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: 0x9F7D4D))
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fortuneInputChrome(tone: tone)
        .opacity(isEnabled ? 1 : 0.6)
        .sheet(isPresented: $isPickerPresented) {
            FortuneBirthDatePickerSheet(
                initialDate: FortuneBirthDateSupport.resolvedDate(from: text)
            ) { selectedDate in
                text = FortuneBirthDateSupport.storageFormatter.string(from: selectedDate)
            }
        }
    }

    private var displayText: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "请选择出生日期" : trimmed
    }
}

private struct FortuneBirthDatePickerSheet: View {
    let initialDate: Date
    let onConfirm: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var components: FortuneBirthDateComponents

    init(
        initialDate: Date,
        onConfirm: @escaping (Date) -> Void
    ) {
        self.initialDate = initialDate
        self.onConfirm = onConfirm
        _components = State(initialValue: FortuneBirthDateSupport.resolvedComponents(from: initialDate))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("请选择出生日期")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: 0xE2C89A))
                .padding(.top, 18)

            Text(selectedSummary)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundStyle(Color(hex: 0xC9AE79))
                .minimumScaleFactor(0.88)

            HStack(spacing: 0) {
                pickerColumn(
                    title: "年",
                    selection: $components.year,
                    values: FortuneBirthDateSupport.years
                ) { value in
                    "\(value)年"
                }

                pickerColumn(
                    title: "月",
                    selection: $components.month,
                    values: FortuneBirthDateSupport.months
                ) { value in
                    "\(value)月"
                }

                pickerColumn(
                    title: "日",
                    selection: $components.day,
                    values: validDays
                ) { value in
                    "\(value)日"
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 216)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: 0x1B140F))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: 0x6E5A3B), lineWidth: 1)
            )

            HStack(spacing: 10) {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(FortuneSecondaryButtonStyle())

                Button("确定") {
                    onConfirm(
                        FortuneBirthDateSupport.date(
                            year: components.year,
                            month: components.month,
                            day: components.day
                        )
                    )
                    dismiss()
                }
                .buttonStyle(FortunePrimaryButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(hex: 0x0F0B08).ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onChange(of: components.year) { _, _ in
            clampDayIfNeeded()
        }
        .onChange(of: components.month) { _, _ in
            clampDayIfNeeded()
        }
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hex: 0x0F0B08))
    }

    private var validDays: [Int] {
        FortuneBirthDateSupport.days(forYear: components.year, month: components.month)
    }

    private var selectedSummary: String {
        "\(components.year)年 \(components.month)月 \(components.day)日"
    }

    private func clampDayIfNeeded() {
        if let maxDay = validDays.last, components.day > maxDay {
            components.day = maxDay
        }
    }

    private func pickerColumn(
        title: String,
        selection: Binding<Int>,
        values: [Int],
        label: @escaping (Int) -> String
    ) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: 0x9F7D4D))

            Picker(title, selection: selection) {
                ForEach(values, id: \.self) { value in
                    Text(label(value))
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundStyle(Color(hex: 0xE2C89A))
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipped()
        }
        .frame(maxWidth: .infinity)
    }
}

enum FortunePopupTone {
    case light
    case dark

    var strokeColor: Color {
        switch self {
        case .light:
            Color(hex: 0xAA7C45)
        case .dark:
            Color(hex: 0x6B563A)
        }
    }

    var shadowColor: Color {
        Color.black.opacity(0.24)
    }
}

struct FortunePopupSurface<Content: View>: View {
    var tone: FortunePopupTone
    var maxWidth: CGFloat = 358
    var maxHeight: CGFloat? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: maxWidth)
            .frame(maxHeight: maxHeight)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(tone.strokeColor, lineWidth: 1)
            )
            .shadow(color: tone.shadowColor, radius: 24, y: 12)
            .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch tone {
        case .light:
            Color(hex: 0xF7EBD7)
        case .dark:
            LinearGradient(
                colors: [Color(hex: 0x0C0A07), Color(hex: 0x1E1610)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

enum FortuneFieldCatalog {
    static let hourOptions = [
        "子时 (23:00-01:00)",
        "丑时 (01:00-03:00)",
        "寅时 (03:00-05:00)",
        "卯时 (05:00-07:00)",
        "辰时 (07:00-09:00)",
        "巳时 (09:00-11:00)",
        "午时 (11:00-13:00)",
        "未时 (13:00-15:00)",
        "申时 (15:00-17:00)",
        "酉时 (17:00-19:00)",
        "戌时 (19:00-21:00)",
        "亥时 (21:00-23:00)"
    ]

    static let genders = ["男", "女"]
    static let calendars = ["公历", "农历"]
}

enum FortuneValidation {
    static func isValidDate(_ dateText: String) -> Bool {
        let trimmed = dateText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil else {
            return false
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter.date(from: trimmed) != nil
    }

    static func isValidBirthHour(_ hourLabel: String) -> Bool {
        FortuneFieldCatalog.hourOptions.contains(hourLabel.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func isValidGender(_ gender: String) -> Bool {
        FortuneFieldCatalog.genders.contains(gender.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func isValidCalendarType(_ calendarType: String) -> Bool {
        FortuneFieldCatalog.calendars.contains(calendarType.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func isCompleteBirthInput(
        birthDate: String,
        birthHourLabel: String,
        gender: String,
        calendarType: String
    ) -> Bool {
        isValidDate(birthDate)
            && isValidBirthHour(birthHourLabel)
            && isValidGender(gender)
            && isValidCalendarType(calendarType)
    }
}

enum FortuneLocalHeuristics {
    static func stableStringValue(_ text: String) -> Int {
        text.unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult + Int(scalar.value)
        }
    }

    static func birthDateDigits(_ birthDate: String) -> Int {
        Int(birthDate.filter(\.isNumber)) ?? 0
    }

    static func hourIndex(for hourLabel: String) -> Int {
        FortuneFieldCatalog.hourOptions.firstIndex(of: hourLabel) ?? 0
    }

    static func dayOfYear(for date: Date) -> Int {
        Calendar(identifier: .gregorian).ordinality(of: .day, in: .year, for: date) ?? 0
    }

    static func pickUniqueValues<T>(from source: [T], seed: Int, count: Int) -> [T] {
        guard !source.isEmpty else { return [] }

        var results: [T] = []
        var visited: Set<Int> = []
        var cursor = abs(seed)

        while results.count < min(count, source.count) {
            let index = cursor % source.count
            if !visited.contains(index) {
                visited.insert(index)
                results.append(source[index])
            }
            cursor = cursor / 2 + 11
        }

        return results
    }
}
