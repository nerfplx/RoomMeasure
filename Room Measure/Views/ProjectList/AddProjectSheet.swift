import SwiftUI

struct AddProjectSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isPresented: Bool
    @Binding var projectName: String
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.adaptiveBackground(for: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: AppSpacing.lg) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }
                    .padding(.top, AppSpacing.xl)

                    VStack(spacing: AppSpacing.md) {
                        Text(LocalizedKey.projectsNew.localized)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.adaptivePrimaryText(for: colorScheme))

                        TextField(LocalizedKey.projectsNamePlaceholder.localized, text: $projectName)
                            .font(.body)
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
                    .padding(AppSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.large)
                            .fill(AppColors.adaptiveBackground(for: colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.large)
                            .stroke(AppColors.adaptiveBorder(for: colorScheme), lineWidth: AppBorders.medium)
                    )
                    .shadow(color: AppColors.adaptiveShadow(for: colorScheme), radius: 12, x: 0, y: 6)
                    .padding(.horizontal, AppSpacing.lg)

                    Spacer()
                }
            }
            .navigationTitle(LocalizedKey.projectsNew.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedKey.projectsCancel.localized) {
                        isPresented = false
                        projectName = ""
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedKey.projectsCreate.localized) {
                        onSave()
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
            }
        }
    }
}
