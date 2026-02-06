import SwiftUI
import RoomPlan
import simd

struct DimensionRow: View {
    let label: String
    let value: Float
    let unit: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(String(format: "%.2f %@", value, unit))
                .foregroundColor(.secondary)
                .font(.system(.body, design: .monospaced))
        }
    }
}

struct WallRow: View {
    let index: Int
    let wall: CapturedRoom.Surface

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "square.fill")
                    .foregroundColor(.blue)
                Text("\(LocalizedKey.roomWall.localized) \(index)")
                    .font(.headline)
            }

            HStack {
                Text("room.results.dimensions.label".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatDimensions(wall.dimensions))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDimensions(_ dimensions: simd_float3) -> String {
        "\(UnitHelper.length(dimensions.x)) × \(UnitHelper.length(dimensions.y)) × \(UnitHelper.length(dimensions.z))"
    }

}

struct ObjectRow: View {
    let icon: String
    let name: String
    let dimensions: simd_float3

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(name)

            Spacer()

            Text(formatDimensions(dimensions))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func formatDimensions(_ dimensions: simd_float3) -> String {
          "\(UnitHelper.length(dimensions.x)) × \(UnitHelper.length(dimensions.y))"
      }
}
