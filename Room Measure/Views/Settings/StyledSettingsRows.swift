import SwiftUI

struct StyledSettingsSection<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(AppColors.adaptiveBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .stroke(AppColors.adaptiveBorder(for: colorScheme), lineWidth: AppBorders.thin)
        )
        .shadow(color: AppColors.adaptiveShadow(for: colorScheme), radius: 6, x: 0, y: 3)
    }
}

struct StyledToggleRow: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 20, height: 20)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
            }

            Text(title)
                .font(.system(size: 16))
                .foregroundColor(AppColors.adaptivePrimaryText(for: colorScheme))

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(AppSpacing.sm)
    }
}

struct StyledPickerRow<SelectionValue: Hashable, Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let title: String
    @Binding var selection: SelectionValue
    let content: Content

    init(
        icon: String,
        title: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self._selection = selection
        self.content = content()
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 20, height: 20)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
            }

            Text(title)
                .font(.system(size: 16))
                .foregroundColor(AppColors.adaptivePrimaryText(for: colorScheme))

            Spacer()

            Picker("", selection: $selection) {
                content
            }
            .pickerStyle(.menu)
        }
        .padding(AppSpacing.sm)
    }
}
