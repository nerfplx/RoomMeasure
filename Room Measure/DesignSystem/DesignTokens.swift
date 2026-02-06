import SwiftUI

struct AppColors {
    static func adaptiveBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: 0.1) : .white
    }

    static func adaptiveSecondaryBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: 0.15) : Color(.systemGray6)
    }

    static func adaptiveTertiaryBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: 0.2) : Color(.systemGray5)
    }

    static func adaptiveBorder(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.1)
    }

    static func adaptiveShadow(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.6) : Color.black.opacity(0.15)
    }

    static func adaptivePrimaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : .black
    }

    static func adaptiveSecondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.6)
    }
}

struct AppSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48

    static let bottomInsetObject3D: CGFloat = 60
    static let handleSize:          CGFloat = 28
    static let cameraTopPadding:    CGFloat = 50
    static let toolbarBottomInset:  CGFloat = 110

    static let onboardingIconSize:       CGFloat = 120
    static let onboardingIconInner:      CGFloat = 52
    static let onboardingTitleBottom:    CGFloat = 12
    static let onboardingIconBottom:     CGFloat = 32
    static let onboardingListBottom:     CGFloat = 36
    static let onboardingDestBottom:     CGFloat = 28
    static let onboardingButtonPadV:     CGFloat = 18
    static let onboardingInstructionSpacing: CGFloat = 16
    static let onboardingInstructionIconW:   CGFloat = 24
    static let onboardingGridStep:       CGFloat = 40

    static let onboardingPulseInner: CGFloat = 1.08
    static let onboardingPulseOuter: CGFloat = 1.15
}

struct AppCornerRadius {
    static let small:      CGFloat = 8
    static let medium:     CGFloat = 12
    static let large:      CGFloat = 16
    static let extraLarge: CGFloat = 24
    static let button:     CGFloat = 18
}

struct AppBorders {
    static let thin:   CGFloat = 1
    static let medium: CGFloat = 2
    static let thick:  CGFloat = 3
}

struct AppOpacity {
    static let high:     Double = 0.8
    static let medium:   Double = 0.6
    static let low:      Double = 0.4
    static let subtle:   Double = 0.15
    static let ghost:    Double = 0.08

    static let cameraHidden: Double = 0.001

    static let gridLines:         Double = 0.15
    static let iconFill:          Double = 0.15
    static let iconRing:          Double = 0.3
    static let iconGradientEnd:   Double = 0.8
    static let shadowBlue:        Double = 0.4
    static let textSecondary:     Double = 0.75
    static let textTertiary:      Double = 0.4
    static let destinationBadge:  Double = 0.08
    static let buttonGradientEnd: Double = 0.35
    static let overlayBg:         Double = 0.6
}

struct AppAnimation {
    static let onboardingPulse: Animation = .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    static let onboardingAppear: Animation = .easeInOut(duration: 0.3)
    static let onboardingDismiss: Animation = .easeInOut(duration: 0.2)
}

extension AppColors {
    static let onboardingGradientTop    = Color(red: 0.05, green: 0.07, blue: 0.12)
    static let onboardingGradientBottom = Color(red: 0.08, green: 0.12, blue: 0.20)
}
