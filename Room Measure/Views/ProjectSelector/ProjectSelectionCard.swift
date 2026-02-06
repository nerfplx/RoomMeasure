import SwiftUI

struct ProjectSelectionCard: View {
    let project: MeasurementProject
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 12) {
                        Label("\(project.totalRooms) \(LocalizedKey.projectRooms.localized)", systemImage: "house.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Label("\(project.totalMeasurements) \(LocalizedKey.projectsMeasurements.localized)", systemImage: "ruler")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: AppBorders.medium)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RoomSelectionCard: View {
    let room: Room
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .green : .gray)

                VStack(alignment: .leading, spacing: 4) {
                    Text(room.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if room.hasRoomScan {
                            Image(systemName: "cube.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }

                        Text("\(room.measurementCount) \(LocalizedKey.projectsMeasurements.localized)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let dimensions = room.roomDimensions {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(UnitHelper.area(dimensions.area))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(isSelected ? Color.green.opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(isSelected ? Color.green : Color(.systemGray5), lineWidth: AppBorders.thin)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
