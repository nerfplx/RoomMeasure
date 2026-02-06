import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @AppStorage("measurementUnit") private var measurementUnit = "metric"
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("autoFlashlight") private var autoFlashlight = true

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.adaptiveBackground(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        mainSection
                        themeSection
                        measurementsSection
                        flashlightHintSection
                        dataSection
                    }
                    .padding(AppSpacing.md)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .navigationTitle(LocalizedKey.settingsTitle.localized)
        }
    }

    private var mainSection: some View {
        StyledSettingsSection(
            content: {
                StyledPickerRow(
                    icon: "globe",
                    title: LocalizedKey.settingsLanguage.localized,
                    selection: $localizationManager.currentLanguage
                ) {
                    Text(LocalizedKey.languageEnglish.localized).tag("en")
                    Text(LocalizedKey.languageRussian.localized).tag("ru")
                }
                .onChange(of: localizationManager.currentLanguage) { _, newValue in
                    localizationManager.setLanguage(newValue)
                }
            }
        )
    }

    private var themeSection: some View {
        StyledSettingsSection(
            content: {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(AppTheme.allCases) { theme in
                        ThemeOptionRow(
                            theme: theme,
                            isSelected: themeManager.currentTheme == theme
                        ) {
                            withAnimation(.spring()) {
                                themeManager.setTheme(theme)
                            }
                        }
                    }
                }
            }
        )
    }

    private var measurementsSection: some View {
        StyledSettingsSection(
            content: {
                VStack(spacing: 0) {
                    StyledPickerRow(
                        icon: "chart.bar",
                        title: LocalizedKey.settingsUnits.localized,
                        selection: $measurementUnit
                    ) {
                        Text(LocalizedKey.settingsUnitsMetric.localized).tag("metric")
                        Text(LocalizedKey.settingsUnitsImperial.localized).tag("imperial")
                    }
                    StyledDivider()
                    StyledToggleRow(icon: "hand.tap", title: LocalizedKey.settingsHaptic.localized, isOn: $hapticFeedback)
                    StyledDivider()
                    StyledToggleRow(icon: "flashlight.on.fill", title: LocalizedKey.settingsAutoFlashlight.localized, isOn: $autoFlashlight)
                }
            }
        )
    }

    @ViewBuilder
    private var flashlightHintSection: some View {
        if autoFlashlight {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text(LocalizedKey.settingsAutoFlashlightHint.localized)
                    .font(.caption)
                    .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.small)
                    .fill(Color.blue.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.small)
                    .stroke(Color.blue.opacity(0.3), lineWidth: AppBorders.thin)
            )
            .padding(.horizontal, AppSpacing.md)
        }
    }

    private var dataSection: some View {
        StyledSettingsSection(
            content: {
                NavigationLink(destination: StorageView()) {
                    HStack(spacing: AppSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 20, height: 20)
                            Image(systemName: "internaldrive")
                                .font(.system(size: 18))
                                .foregroundColor(.orange)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedKey.settingsStorage.localized)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.adaptivePrimaryText(for: colorScheme))
                            Text(LocalizedKey.settingsStorageManage.localized)
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
                    }
                    .padding(AppSpacing.sm)
                }
            }
        )
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: MeasurementProject.self, inMemory: true)
}
