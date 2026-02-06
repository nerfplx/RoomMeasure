import SwiftUI

struct StyledProjectRow: View {
    @Environment(\.colorScheme) var colorScheme
    let project: MeasurementProject

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "folder.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(project.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.adaptivePrimaryText(for: colorScheme))
                    .lineLimit(1)

                Label {
                    Text(project.createdDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
                } icon: {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
        }
        .padding(AppSpacing.md)
    }
}

struct ProjectListRow: View {
    let project: MeasurementProject
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            StyledProjectRow(project: project)
        }
        .buttonStyle(PlainButtonStyle())
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label(LocalizedKey.commonDelete.localized, systemImage: "trash")
            }
        }
    }
}
