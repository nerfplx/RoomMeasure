import SwiftUI

struct RoomDimensionsCard: View {
    let dimensions: RoomDimensions

    var body: some View {
        VStack(spacing: 0) {
            InfoDimensionRow(
                label: LocalizedKey.roomLength.localized,
                value: UnitHelper.isImperial ? dimensions.totalWallLength * 3.28084 : dimensions.totalWallLength,
                unit:  UnitHelper.lengthUnit
            )
            Divider().padding(.horizontal, AppSpacing.md)

            InfoDimensionRow(
                label: LocalizedKey.roomHeight.localized,
                value: UnitHelper.isImperial ? dimensions.height * 3.28084 : dimensions.height,
                unit:  UnitHelper.lengthUnit
            )
            Divider().padding(.horizontal, AppSpacing.md)

            InfoDimensionRow(
                label: LocalizedKey.roomArea.localized,
                value: UnitHelper.isImperial ? dimensions.area * 10.7639 : dimensions.area,
                unit:  UnitHelper.areaUnit,
                isHighlighted: true,
                icon: "square.grid.3x3"
            )
            Divider().padding(.horizontal, AppSpacing.md)

            InfoDimensionRow(
                label: LocalizedKey.projectDetailTotalVolume.localized,
                value: UnitHelper.isImperial ? dimensions.volume * 35.3147 : dimensions.volume,
                unit:  UnitHelper.volumeUnit,
                isHighlighted: true,
                icon: "cube"
            )
        }
    }
}

struct InfoDimensionRow: View {
    @Environment(\.colorScheme) var colorScheme
    let label: String
    let value: Float
    let unit: String
    var isHighlighted: Bool = false
    var icon: String = "cube"

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            if isHighlighted {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                }
            }

            Text(label)
                .font(.system(size: 16, weight: isHighlighted ? .medium : .regular))
                .foregroundColor(AppColors.adaptivePrimaryText(for: colorScheme))

            Spacer()

            Text(String(format: "%.2f %@", value, unit))
                .font(.system(size: 16, weight: isHighlighted ? .semibold : .regular))
                .foregroundColor(isHighlighted ? .orange : AppColors.adaptiveSecondaryText(for: colorScheme))
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, isHighlighted ? 14 : 12)
    }
}

struct InfoMeasurementRow: View {
    @Environment(\.colorScheme) var colorScheme
    let measurement: SingleMeasurement

    private var isObjectMeasurement: Bool { measurement.objectHeight != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                ZStack {
                    Circle()
                        .fill((isObjectMeasurement ? Color.purple : Color.green).opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: isObjectMeasurement ? "viewfinder.rectangular" : "ruler")
                        .font(.system(size: 18))
                        .foregroundColor(isObjectMeasurement ? .purple : .green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(measurement.name)
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.adaptivePrimaryText(for: colorScheme))
                    if let height = measurement.objectHeight {
                                           Text(UnitHelper.size(measurement.distance, height))
                                               .font(.system(size: 13))
                                               .foregroundColor(.purple)
                                       } else {
                                           Text(UnitHelper.length(measurement.distance))
                                               .font(.system(size: 13))
                                               .foregroundColor(.green)
                                       }
                }
            }

            let visibleNotes = measurement.notes

            if let notes = visibleNotes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
                    .italic()
                    .lineLimit(3)
                    .padding(.leading)
            }

            HStack {
                Spacer()
                Text(measurement.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 13))
                    .italic()
                    .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
            }
        }
        .padding(AppSpacing.sm)
    }
}
