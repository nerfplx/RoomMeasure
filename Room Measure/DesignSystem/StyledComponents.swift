import SwiftUI

struct StyledCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    let padding: CGFloat
    
    init(padding: CGFloat = AppSpacing.md, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(AppColors.adaptiveBackground(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(AppColors.adaptiveBorder(for: colorScheme), lineWidth: AppBorders.thin)
            )
            .shadow(
                color: AppColors.adaptiveShadow(for: colorScheme),
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

struct StyledButton: View {
    @Environment(\.colorScheme) var colorScheme
    
    let title: String
    let icon: String?
    let style: ButtonStyleType
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyleType = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(textColor)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(borderColor, lineWidth: AppBorders.medium)
            )
            .shadow(
                color: shadowColor,
                radius: 6,
                x: 0,
                y: 3
            )
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return .blue
        case .secondary:
            return AppColors.adaptiveSecondaryBackground(for: colorScheme)
        case .success:
            return .green
        case .danger:
            return .red
        case .ghost:
            return .clear
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .success, .danger:
            return .white
        case .secondary, .ghost:
            return AppColors.adaptivePrimaryText(for: colorScheme)
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .ghost:
            return AppColors.adaptiveBorder(for: colorScheme)
        case .primary:
            return Color.blue.opacity(0.3)
        case .secondary:
            return AppColors.adaptiveBorder(for: colorScheme)
        case .success:
            return Color.green.opacity(0.3)
        case .danger:
            return Color.red.opacity(0.3)
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary:
            return Color.blue.opacity(colorScheme == .dark ? 0.4 : 0.3)
        case .success:
            return Color.green.opacity(colorScheme == .dark ? 0.4 : 0.3)
        case .danger:
            return Color.red.opacity(colorScheme == .dark ? 0.4 : 0.3)
        case .secondary, .ghost:
            return AppColors.adaptiveShadow(for: colorScheme)
        }
    }
}

enum ButtonStyleType {
    case primary
    case secondary
    case success
    case danger
    case ghost
}

struct StyledSectionHeader: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let icon: String?
    
    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
            }
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
                .textCase(.uppercase)
        }
    }
}

struct StyledInfoRow: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    
    init(icon: String, title: String, value: String, iconColor: Color = .blue) {
        self.icon = icon
        self.title = title
        self.value = value
        self.iconColor = iconColor
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.adaptivePrimaryText(for: colorScheme))
            }
            
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.small)
                .fill(AppColors.adaptiveSecondaryBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.small)
                .stroke(AppColors.adaptiveBorder(for: colorScheme), lineWidth: AppBorders.thin)
        )
    }
}

struct StyledBadge: View {
    @Environment(\.colorScheme) var colorScheme
    let text: String
    let color: Color
    
    init(_ text: String, color: Color = .blue) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color)
            )
            .shadow(
                color: color.opacity(0.3),
                radius: 3,
                x: 0,
                y: 2
            )
    }
}

struct StyledDivider: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Rectangle()
            .fill(AppColors.adaptiveBorder(for: colorScheme))
            .frame(height: AppBorders.thin)
    }
}

struct StyledEmptyState: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(AppColors.adaptiveSecondaryBackground(for: colorScheme))
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
            }
            
            VStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.adaptivePrimaryText(for: colorScheme))
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                StyledButton(actionTitle, icon: "plus.circle.fill", style: .primary, action: action)
                    .padding(.top, AppSpacing.sm)
            }
        }
        .padding(AppSpacing.xl)
    }
}
