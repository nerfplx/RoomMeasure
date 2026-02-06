import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("appTheme") var currentTheme: AppTheme = .dark {
        didSet { applyTheme() }
    }

    private init() { applyTheme() }

    func setTheme(_ theme: AppTheme) { currentTheme = theme }

    private func applyTheme() { objectWillChange.send() }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case light = "light"
    case dark  = "dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark:  return .dark
        }
    }

    var localizedName: String {
        switch self {
        case .light: return LocalizedKey.themeLightMode.localized
        case .dark:  return LocalizedKey.themeDarkMode.localized
        }
    }

    var iconName: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark:  return "moon.fill"
        }
    }
}
