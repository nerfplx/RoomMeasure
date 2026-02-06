import SwiftUI

struct RoomRow: View {
    @Environment(\.colorScheme) var colorScheme
    let room: Room
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: room.hasRoomScan ? "cube.fill" : "house")
                    .font(.system(size: 18))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(room.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.adaptivePrimaryText(for: colorScheme))
                
                HStack(spacing: 12) {
                    if let dimensions = room.roomDimensions {
                        Text(UnitHelper.area(dimensions.area))
                            .font(.system(size: 13))
                            .foregroundColor(.orange)
                    }
                    if room.measurementCount > 0 {
                        Text("\(room.measurementCount) \(LocalizedKey.projectsMeasurements.localized)")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green.opacity(0.5))
        }
        .padding(AppSpacing.md)
    }
}

struct RoomListRow: View {
    let room: Room
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            RoomRow(room: room)
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
