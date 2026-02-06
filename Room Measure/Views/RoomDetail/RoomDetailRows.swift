import SwiftUI

struct Model3DRow: View {
    @Environment(\.colorScheme) var colorScheme
    let fileSize: String?
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "cube.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedKey.projectDetail3DModel.localized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.adaptivePrimaryText(for: colorScheme))
                
                if let fileSize {
                    Text("\(LocalizedKey.projectDetailFileSize.localized): \(fileSize)")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.blue)
        }
        .padding(AppSpacing.md)
    }
}

struct ActionRow: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let iconColor: Color
    let title: String
    
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
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(iconColor.opacity(0.5))
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(AppColors.adaptiveBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .stroke(AppColors.adaptiveBorder(for: colorScheme), lineWidth: AppBorders.medium)
        )
        .shadow(color: AppColors.adaptiveShadow(for: colorScheme), radius: 8, x: 0, y: 4)
    }
}

struct NotesContentRow: View {
    @Environment(\.colorScheme) var colorScheme
    let notes: String
    let createdAt: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(notes)
                .font(.system(size: 13))
                .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
                .lineLimit(3)
                .italic()
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 4)
            HStack {
                Spacer()
                Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .italic()
                    .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
            }
            .padding(.bottom)
        }
        .padding(AppSpacing.md)
        .frame(maxHeight: .infinity)
    }
}

struct EmptyNotesRow: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "plus")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
            }
            
            Text(LocalizedKey.projectDetailAddNotes.localized)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.blue.opacity(0.5))
        }
        .padding(AppSpacing.md)
        .frame(minHeight: 80)
    }
}
