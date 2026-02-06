import SwiftUI

struct ThemeOptionRow: View {
    @Environment(\.colorScheme) var colorScheme
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue.opacity(0.15) : AppColors.adaptiveSecondaryBackground(for: colorScheme))
                        .frame(width: 20, height: 20)
                    Image(systemName: theme.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? .blue : AppColors.adaptiveSecondaryText(for: colorScheme))
                }

                Text(theme.localizedName)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(AppColors.adaptivePrimaryText(for: colorScheme))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.small)
                    .fill(isSelected ? Color.blue.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
